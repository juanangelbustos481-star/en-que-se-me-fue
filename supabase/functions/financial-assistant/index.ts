// Supabase Edge Function: financial-assistant
// Set OPENAI_API_KEY as a Supabase secret. Never place it in browser code.
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return new Response(JSON.stringify({ error: "Method not allowed" }), { status: 405, headers: { ...corsHeaders, "Content-Type": "application/json" } });

  const apiKey = Deno.env.get("OPENAI_API_KEY");
  if (!apiKey) return new Response(JSON.stringify({ error: "AI_NOT_CONFIGURED" }), { status: 503, headers: { ...corsHeaders, "Content-Type": "application/json" } });

  try {
    const body = await req.json();
    const question = String(body?.question ?? "").trim().slice(0, 600);
    if (!question) return new Response(JSON.stringify({ error: "Question required" }), { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } });

    const raw = body?.summary ?? {};
    // Accept only aggregate financial fields; no names, notes, emails, or raw transaction descriptions.
    const summary = {
      month: String(raw.month ?? "").slice(0, 7),
      spent: Number(raw.spent) || 0,
      income: Number(raw.income) || 0,
      balance: Number(raw.balance) || 0,
      budget: Number(raw.budget) || 0,
      previousMonthSpent: Number(raw.previousMonthSpent) || 0,
      movementCount: Math.max(0, Math.min(10000, Number(raw.movementCount) || 0)),
      topCategories: Array.isArray(raw.topCategories) ? raw.topCategories.slice(0, 5).map((x: any) => ({ category: String(x.category ?? "").slice(0, 40), amount: Number(x.amount) || 0 })) : [],
      goals: Array.isArray(raw.goals) ? raw.goals.slice(0, 8).map((x: any) => ({ name: String(x.name ?? "").slice(0, 40), target: Number(x.target) || 0, saved: Number(x.saved) || 0 })) : [],
      upcomingPayments: Array.isArray(raw.upcomingPayments) ? raw.upcomingPayments.slice(0, 8).map((x: any) => ({ name: String(x.name ?? "").slice(0, 40), amount: Number(x.amount) || 0, date: String(x.date ?? "").slice(0, 10), frequency: String(x.frequency ?? "").slice(0, 20) })) : [],
    };

    const model = Deno.env.get("OPENAI_MODEL") || "gpt-6.2-astra";
    const response = await fetch("https://api.openai.com/v1/responses", {
      method: "POST",
      headers: { "Authorization": "Bearer " + apiKey, "Content-Type": "application/json" },
      body: JSON.stringify({
        model,
        max_output_tokens: 450,
        instructions: "Eres un asistente educativo de organización del presupuesto personal. Responde en español claro, breve y amable. Usa únicamente los datos agregados entregados. No solicites datos personales, no recomiendes inversiones, créditos, productos financieros ni decisiones de alto riesgo. No afirmes que puedes ver cuentas bancarias. Propón hábitos generales y cálculos transparentes. Si faltan datos, dilo.",
        input: "Datos agregados del usuario (MXN): " + JSON.stringify(summary) + "\nPregunta: " + question,
      }),
    });

    const payload = await response.json();
    if (!response.ok) return new Response(JSON.stringify({ error: "AI_PROVIDER_ERROR", detail: payload?.error?.message ?? "Provider request failed" }), { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } });
    const answer = (payload.output ?? []).flatMap((item: any) => item.type === "message" ? (item.content ?? []).filter((part: any) => part.type === "output_text").map((part: any) => part.text) : []).join("\n").trim();
    if (!answer) throw new Error("Empty model response");
    return new Response(JSON.stringify({ answer }), { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } });
  } catch (error) {
    return new Response(JSON.stringify({ error: "INTERNAL_ERROR", detail: String(error).slice(0, 240) }), { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } });
  }
});
