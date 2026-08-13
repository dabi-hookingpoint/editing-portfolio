// AI 도구 API 공용 인증/권한 검증. Cloudflare Pages Functions에서 실행되며,
// 클라이언트가 보낸 Supabase access token을 검증하고 profiles.role/ai_tools_access를 확인합니다.
// 서비스 롤 키 없이, 사용자 본인 토큰으로 Supabase REST API를 직접 호출합니다.
//
// IP DEVELOPMENT(회의 녹음/자동요약 · 3막 구조 분석 · 레퍼런스 · 컨셉 이미지)는
// 로그인 없이 누구나 쓸 수 있도록 열어달라는 요청에 따라 검증을 꺼둔 상태입니다.
const AI_TOOLS_AUTH_ENABLED = false;

export function jsonError(status, message) {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { "content-type": "application/json" },
  });
}

export async function requireAiToolsAccess(request, env) {
  if (!AI_TOOLS_AUTH_ENABLED) return { user: { id: "anonymous" } };

  const authHeader = request.headers.get("authorization") || "";
  const token = authHeader.replace(/^Bearer\s+/i, "").trim();
  if (!token) return { error: jsonError(401, "로그인이 필요합니다.") };

  const supabaseUrl = env.PUBLIC_SUPABASE_URL;
  const supabaseAnonKey = env.PUBLIC_SUPABASE_ANON_KEY;
  if (!supabaseUrl || !supabaseAnonKey) {
    return { error: jsonError(500, "서버 설정 오류: Supabase 키가 설정되지 않았습니다.") };
  }

  const userRes = await fetch(`${supabaseUrl}/auth/v1/user`, {
    headers: { authorization: `Bearer ${token}`, apikey: supabaseAnonKey },
  });
  if (!userRes.ok) return { error: jsonError(401, "유효하지 않은 로그인입니다. 다시 로그인해주세요.") };
  const user = await userRes.json();

  const profileRes = await fetch(
    `${supabaseUrl}/rest/v1/profiles?id=eq.${user.id}&select=role,ai_tools_access`,
    { headers: { authorization: `Bearer ${token}`, apikey: supabaseAnonKey } }
  );
  if (!profileRes.ok) return { error: jsonError(500, "권한 확인 중 오류가 발생했습니다.") };
  const profiles = await profileRes.json();
  const profile = profiles?.[0];
  const allowed = !!profile && (profile.role === "admin" || profile.ai_tools_access === true);
  if (!allowed) return { error: jsonError(403, "AI 도구 사용 권한이 없습니다. 관리자에게 권한 부여를 요청해주세요.") };

  return { user };
}
