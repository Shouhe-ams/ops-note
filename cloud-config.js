/*
 * 公开的 Supabase 客户端配置。
 * publishable / anon key 本来就会发送给浏览器，安全边界由数据库 RLS 保证。
 * 绝对不要把 service_role / secret key 放到这个文件。
 */
window.OPS_CLOUD = {
  supabaseUrl: "https://kfzqiaquucqgvklcqals.supabase.co",
  supabaseKey: "sb_publishable_VV5z1y_xWxzIKa0BLntH1Q_MeJcZUz6"
};
