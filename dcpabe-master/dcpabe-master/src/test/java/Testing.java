import it.unisa.dia.gas.jpbc.Element;
import it.unisa.dia.gas.jpbc.Pairing;
import it.unisa.dia.gas.plaf.jpbc.pairing.PairingFactory;
import it.unisa.dia.gas.plaf.jpbc.pairing.a.TypeACurveGenerator;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.junit.runners.JUnit4;
import sg.edu.ntu.sce.sands.crypto.dcpabe.*;
import sg.edu.ntu.sce.sands.crypto.dcpabe.ac.AccessStructure;
import sg.edu.ntu.sce.sands.crypto.dcpabe.key.PersonalKey;

import java.security.SecureRandom;
import java.sql.SQLOutput;

import static org.junit.Assert.assertArrayEquals;
import static org.junit.Assert.assertTrue;


@RunWith(JUnit4.class)
public class Testing {
    @Test
    public void testDCPABE2() {
        System.out.println("开始执行 testDCPABE2...");

        GlobalParameters gp = DCPABE.globalSetup(160);
        System.out.println("全局参数设置完成：" + gp.toString());

        PublicKeys publicKeys = new PublicKeys();
        //设置属性
        AuthorityKeys authority1 = DCPABE.authoritySetup("a1", gp, "a", "b");
        publicKeys.subscribeAuthority(authority1.getPublicKeys());
        System.out.println("权威1设置完成：" + authority1.toString());

        AuthorityKeys authority2 = DCPABE.authoritySetup("a2", gp, "c", "d");
        publicKeys.subscribeAuthority(authority2.getPublicKeys());
        System.out.println("权威2设置完成：" + authority2.toString());
        System.out.println("publicKeys:"+publicKeys);
        //user1
        PersonalKeys pkeys = new PersonalKeys("user");
        PersonalKey keyA = DCPABE.keyGen("user", "a", authority1.getSecretKeys().get("a"), gp);
        PersonalKey keyD = DCPABE.keyGen("user", "d", authority2.getSecretKeys().get("d"), gp);
        pkeys.addKey(keyA);
        pkeys.addKey(keyD);

        //user2
        PersonalKeys User2 = new PersonalKeys("user2");
        PersonalKey keyC = DCPABE.keyGen("user2", "c", authority2.getSecretKeys().get("c"), gp);
        User2.addKey(keyC);

        System.out.println("User1密钥生成完成：");
        System.out.println("Key for attribute 'a': " + keyA.toString());
        System.out.println("Key for attribute 'd': " + keyD.toString());
        //System.out.println("User2密钥生成完成：---------");
        //System.out.println("Key for attribute 'c': " + keyC.toString());
        //设置访问权限
        AccessStructure as = AccessStructure.buildFromPolicy("and a or d and b c");
        System.out.println("访问结构构建完成：" + as.toString());
        //byte[] m = {"",};
        Message message = DCPABE.generateRandomMessage(gp);
        System.out.println("生成随机消息：" + message.toString());

        Ciphertext ct = DCPABE.encrypt(message, as, gp, publicKeys);
        System.out.println("消息加密完成：" + ct.toString());
        //user1解密
        Message decryptedMessage = DCPABE.decrypt(ct, pkeys, gp);
        System.out.println("User1消息解密完成：" + decryptedMessage.toString());
        //user2机密
//        Message decryptedMessage2 = DCPABE.decrypt(ct, User2, gp);
//        //decryptedMessage = DCPABE.decrypt(ct, User2, gp);
//        System.out.println("User2消息解密完成：" + decryptedMessage2.toString());

        assertArrayEquals(message.getM(), decryptedMessage.getM());


        System.out.println("testDCPABE2 执行完成");
    }



    @Test
    public void testDCPABE1() {
        GlobalParameters gp = DCPABE.globalSetup(160);

        PublicKeys publicKeys = new PublicKeys();

        AuthorityKeys authority0 = DCPABE.authoritySetup("a1", gp, "a", "b", "c", "d");
        publicKeys.subscribeAuthority(authority0.getPublicKeys());

        AccessStructure as = AccessStructure.buildFromPolicy("and a or d and b c");

        PersonalKeys pkeys = new PersonalKeys("user");
        PersonalKey k_user_a = DCPABE.keyGen("user", "a", authority0.getSecretKeys().get("a"), gp);
        PersonalKey k_user_d = DCPABE.keyGen("user", "d", authority0.getSecretKeys().get("d"), gp);
        pkeys.addKey(k_user_a);
        pkeys.addKey(k_user_d);

        Message message = DCPABE.generateRandomMessage(gp);
        Ciphertext ct = DCPABE.encrypt(message, as, gp, publicKeys);

        Message dMessage = DCPABE.decrypt(ct, pkeys, gp);

        assertArrayEquals(message.getM(), dMessage.getM());
    }

    @Test
    public void testBilinearity() {
        SecureRandom random = new SecureRandom("12345".getBytes());
        Pairing pairing = PairingFactory.getPairing(new TypeACurveGenerator(random, 181, 603, true).generate());

        Element g1 = pairing.getG1().newRandomElement().getImmutable();
        Element g2 = pairing.getG2().newRandomElement().getImmutable();

        Element a = pairing.getZr().newRandomElement().getImmutable();
        Element b = pairing.getZr().newRandomElement().getImmutable();

        Element ga = g1.powZn(a);
        Element gb = g2.powZn(b);

        Element gagb = pairing.pairing(ga, gb);

        Element ggab = pairing.pairing(g1, g2).powZn(a.mulZn(b));

        assertTrue(gagb.isEqual(ggab));
    }
}
