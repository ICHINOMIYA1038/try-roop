/// 管理者権限を持つメールアドレスのリスト
const List<String> adminEmails = [
  'ichiryo108@gmail.com',
];

/// メールアドレスが管理者かどうかを判定
bool isAdminEmail(String? email) {
  if (email == null) return false;
  return adminEmails.contains(email.toLowerCase());
}
