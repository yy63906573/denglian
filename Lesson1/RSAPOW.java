package Lesson1;
import javax.crypto.Cipher;
import java.math.BigInteger;
import java.nio.charset.StandardCharsets;
import java.security.*;
import java.security.spec.RSAPublicKeySpec;
import java.util.Base64;

public class RSAPOW {

    // 生成 RSA 密钥对
    public static KeyPair generateRSAKeyPair() throws NoSuchAlgorithmException {
        KeyPairGenerator kpg = KeyPairGenerator.getInstance("RSA");
        kpg.initialize(1024);
        return kpg.generateKeyPair();
    }

    // SHA-256 哈希函数
    public static String sha256(String input) {
         try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");

            byte[] hash = digest.digest(input.getBytes());
            StringBuilder hexString = new StringBuilder();
            for (byte b : hash) {
                String hex = Integer.toHexString(0xff & b);
                if(hex.length() == 1) hexString.append('0');
                hexString.append(hex);
            }
            return hexString.toString();
        } catch(NoSuchAlgorithmException e) {
            throw new RuntimeException(e);
        }
    }

    // 寻找符合 POW 的 "昵称 + nonce"
    public static String findPOWString(String nickname,int zeroCount) {
        int nonce = 0;
        String prefix = "0".repeat(zeroCount);
        while (true) {
            String data = nickname + nonce;
            String hash = sha256(data);
            if (hash.startsWith(prefix)) {
                System.out.println("✅ Found valid POW hash: " + hash);
                System.out.println("   Data: " + data);
                return data;
            }
            nonce++;
        }
    }

    // 私钥签名
    public static String signData(PrivateKey privateKey, String data) throws Exception {
        Signature signature = Signature.getInstance("SHA256withRSA");
        signature.initSign(privateKey);
        signature.update(data.getBytes());
        byte[] signed = signature.sign();
        return Base64.getEncoder().encodeToString(signed);
    }

    // 公钥验证签名
    public static boolean verifySignature(PublicKey publicKey, String data, String signatureStr) throws Exception {
        Signature signature = Signature.getInstance("SHA256withRSA");
        signature.initVerify(publicKey);
        signature.update(data.getBytes());
        byte[] decodedSignature = Base64.getDecoder().decode(signatureStr);
        return signature.verify(decodedSignature);
    }

    // Base64 编码简化输出
    private static String encodeKey(Key key) {
        return Base64.getEncoder().encodeToString(key.getEncoded());

    }

    public static void main(String[] args) throws Exception {   


        String nickname = "yy6390673";

        // Step 1: 生成密钥对
        KeyPair keyPair = generateRSAKeyPair();
        // 获取公钥
        PublicKey publicKey = keyPair.getPublic();
        // 获取私钥
        PrivateKey privateKey = keyPair.getPrivate();

        System.out.println("🔐 Generated RSA key pair:");
        System.out.println("Public Key: " + encodeKey(publicKey));
        System.out.println("Private Key: " + encodeKey(privateKey));

        // Step 2: 模拟pow 挖矿
        String powData = findPOWString(nickname,4);

        // Step 3: 签名
        String signature = signData(privateKey, powData);
        System.out.println("✍️  Signature: " + signature);

        // Step 4: 验证
        boolean isValid = verifySignature(publicKey, powData, signature);
        System.out.println("✅ Signature valid: " + isValid);
    }
}