// 指定したユーザーに admin custom claim を付与/取り消しするスクリプト。
// 管理画面 (site/app/admin) の AuthGuard と firestore.rules はこの claim を見ている。
//
// 認証: tool/serviceAccountKey.json があれば優先、無ければ ADC。
//
// 使い方:
//   node setAdminClaim.js grant <email>
//   node setAdminClaim.js grant <email> --uid       # email ではなく uid 直接指定
//   node setAdminClaim.js revoke <email>
//   node setAdminClaim.js list                       # admin claim を持つユーザー一覧
//
// 付与後、対象ユーザーは管理画面で "再読込" ボタン (もしくは再ログイン) すると
// 新しい claim が反映されます。

const admin = require("firebase-admin");
const fs = require("fs");
const path = require("path");

const keyPath = path.join(__dirname, "serviceAccountKey.json");
if (fs.existsSync(keyPath)) {
  admin.initializeApp({
    credential: admin.credential.cert(require(keyPath)),
  });
  console.log("Authenticated via serviceAccountKey.json");
} else {
  admin.initializeApp({ projectId: "try-roop" });
  console.log("Authenticated via Application Default Credentials");
}

const auth = admin.auth();

async function resolveUser(identifier, asUid) {
  if (asUid) {
    return await auth.getUser(identifier);
  }
  return await auth.getUserByEmail(identifier);
}

async function grant(identifier, asUid) {
  const user = await resolveUser(identifier, asUid);
  const next = { ...(user.customClaims || {}), admin: true };
  await auth.setCustomUserClaims(user.uid, next);
  console.log(`✓ Granted admin to ${user.email ?? user.uid} (uid=${user.uid})`);
}

async function revoke(identifier, asUid) {
  const user = await resolveUser(identifier, asUid);
  const claims = { ...(user.customClaims || {}) };
  delete claims.admin;
  await auth.setCustomUserClaims(user.uid, claims);
  console.log(`✓ Revoked admin from ${user.email ?? user.uid} (uid=${user.uid})`);
}

async function list() {
  const result = await auth.listUsers(1000);
  const admins = result.users.filter((u) => u.customClaims?.admin === true);
  if (admins.length === 0) {
    console.log("(admin claim を持つユーザーは見つかりませんでした)");
    return;
  }
  console.log("admin ロールのユーザー:");
  for (const u of admins) {
    console.log(`  - ${u.email ?? "(no email)"} | uid=${u.uid}`);
  }
  if (result.pageToken) {
    console.log("\n(注意) ユーザー数が 1000 を超えるためページング未対応");
  }
}

async function main() {
  const [, , cmd, identifier, flag] = process.argv;
  const asUid = flag === "--uid";

  switch (cmd) {
    case "grant":
      if (!identifier) throw new Error("使い方: grant <email|uid> [--uid]");
      await grant(identifier, asUid);
      break;
    case "revoke":
      if (!identifier) throw new Error("使い方: revoke <email|uid> [--uid]");
      await revoke(identifier, asUid);
      break;
    case "list":
      await list();
      break;
    default:
      console.error("使い方:");
      console.error("  node setAdminClaim.js grant <email> [--uid]");
      console.error("  node setAdminClaim.js revoke <email> [--uid]");
      console.error("  node setAdminClaim.js list");
      process.exit(1);
  }
}

main()
  .catch((e) => {
    console.error("❌ エラー:", e.message || e);
    process.exit(1);
  })
  .then(() => process.exit(0));
