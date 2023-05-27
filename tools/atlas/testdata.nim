
type
  PerDirData = object
    dirname: string
    cmd: Command
    exitCode: int
    output: string

template toData(a, b, c, d): untyped =
  PerDirData(dirname: a, cmd: b, exitCode: c, output: d)

const
  TestLog = [
    toData("balls", GitPull, 0, "Already up to date.\n"),
    toData("grok", GitDiff, 0, ""),
    toData("grok", GitTags, 0, "2ca193c31fa2377c1e991a080d60ca3215ff6cf0 refs/tags/0.0.1\n48007554b21ba2f65c726ae2fdda88d621865b4a refs/tags/0.0.2\n7092a0286421c7818cd335cca9ebc72d03d866c2 refs/tags/0.0.3\n62707b8ac684efac35d301dbde57dc750880268e refs/tags/0.0.4\n876f2504e0c2f785ffd2cf65a78e2aea474fa8aa refs/tags/0.0.5\nb7eb1f2501aa2382cb3a38353664a13af62a9888 refs/tags/0.0.6\nf5d818bfd6038884b3d8b531c58484ded20a58a4 refs/tags/0.1.0\n961eaddea49c3144d130d105195583d3f11fb6c6 refs/tags/0.2.0\n15ab8ed8d4f896232a976a9008548bd53af72a66 refs/tags/0.2.1\n426a7d7d4603f77ced658e73ad7f3f582413f6cd refs/tags/0.3.0\n83cf7a39b2fe897786fb0fe01a7a5933c3add286 refs/tags/0.3.1\n8d2e3c900edbc95fa0c036fd76f8e4f814aef2c1 refs/tags/0.3.2\n48b43372f49a3bb4dc0969d82a0fca183fb94662 refs/tags/0.3.3\n9ca947a3009ea6ba17814b20eb953272064eb2e6 refs/tags/0.4.0\n1b5643d04fba6d996a16d1ffc13d034a40003f8f refs/tags/0.5.0\n486b0eb580b1c465453d264ac758cc490c19c33e refs/tags/0.5.1\naedb0d9497390e20b9d2541cef2bb05a5cda7a71 refs/tags/0.5.2\n"),
    toData("grok", GitCurrentCommit, 0, "349c15fd1e03f1fcdd81a1edefba3fa6116ab911\n"),
    toData("grok", GitMergeBase, 0, "349c15fd1e03f1fcdd81a1edefba3fa6116ab911\n1b5643d04fba6d996a16d1ffc13d034a40003f8f\n349c15fd1e03f1fcdd81a1edefba3fa6116ab911\n"),
    toData("grok", GitCheckout, 0, "1b5643d04fba6d996a16d1ffc13d034a40003f8f"), # watch out!

    toData("ups", GitDiff, 0, ""),
    toData("ups", GitTags, 0, "4008f9339cd22b30e180bc87a6cca7270fd28ac1 refs/tags/0.0.2\n19bc490c22b4f5b0628c31cdedead1375b279356 refs/tags/0.0.3\nff34602aaea824cb46d6588cd5fe1178132e9702 refs/tags/0.0.4\n09de599138f20b745133b6e4fe563e204415a7e8 refs/tags/0.0.5\n85fee3b74798311108a105635df31f892150f5d0 refs/tags/0.0.6\nfd303913b22b121dc42f332109e9c44950b9acd4 refs/tags/0.0.7\n"),
    toData("ups", GitCurrentCommit, 0, "74c31af8030112dac758440aa51ef175992f71f3\n"),
    toData("ups", GitMergeBase, 0, "74c31af8030112dac758440aa51ef175992f71f3\n4008f9339cd22b30e180bc87a6cca7270fd28ac1\n74c31af8030112dac758440aa51ef175992f71f3\n"),
    toData("ups", GitCheckout, 0, "4008f9339cd22b30e180bc87a6cca7270fd28ac1"),

    toData("sync", GitDiff, 0, ""),
    toData("sync", GitRevParse, 0, "810bd2d75e9f6e182534ae2488670b51a9f13fc3\n"),
    toData("sync", GitCurrentCommit, 0, "de5c7337ebc22422190e8aeca37d05651735f440\n"),
    toData("sync", GitMergeBase, 0, "de5c7337ebc22422190e8aeca37d05651735f440\n810bd2d75e9f6e182534ae2488670b51a9f13fc3\n810bd2d75e9f6e182534ae2488670b51a9f13fc3\n"),

    toData("npeg", GitDiff, 0, ""),
    toData("npeg", GitTags, 0, "8df2f0c9391995fd086b8aab00e8ab7aded1e8f0 refs/tags/0.1.0\n4c959a72db5283b55eeef491076eefb5e02316f1 refs/tags/0.10.0\n802f47c0f7f4318a4f0858ba5a6a6ed2333bde71 refs/tags/0.11.0\n82c8d92837108dce225358ace2c416bf9a3f30ce refs/tags/0.12.0\n87d2f2c4f6ef7da350d45beb5a336611bde7f518 refs/tags/0.13.0\n39964f0d220bfaade47a568bf03c1cf28aa2bc37 refs/tags/0.14.0\nbe9f03f92304cbeab70572944a8563db9b23b2fb refs/tags/0.14.1\na933fb9832566fc95273e417597bfb4faf564ca6 refs/tags/0.15.0\n6aad2e438c52ff0636c7bfb64338e444ac3e83ba refs/tags/0.16.0\nf4ddffb5848c42c6151743dd9c7eddcaaabc56cc refs/tags/0.17.0\n30b446b39442cdbc53a97018ab8a54149aa7c3b7 refs/tags/0.17.1\n1a9d36aa3b34a6169d4530463f1c17a3fe1e075e refs/tags/0.18.0\ndd34f903a9a63b876cb2db19b7a4ce0bcc252134 refs/tags/0.19.0\nd93d49c81fc8722d7929ac463b435c0f2e10c53b refs/tags/0.2.0\neeae7746c9b1118bcf27744ab2aee26969051256 refs/tags/0.20.0\n8c3471a548129f3bf62df15cd0fd8cca1787d852 refs/tags/0.21.0\nc0e873a17bc713c80e74fec3c30cb62dcd5d194a refs/tags/0.21.1\nbae84c47a1bb259b209b6f6be1582327b784539d refs/tags/0.21.2\nbfcb4bcae76a917c3c88736ca773e4cb67dbb2d8 refs/tags/0.21.3\n0eabb7c462d30932049f0b7e6a030c1562cf9fee refs/tags/0.22.0\n2e75367095f54d4351005078bad98041a55b14c1 refs/tags/0.22.1\n814ea235dd398108d7b18f966694c3d951575701 refs/tags/0.22.2\na812064587d983c129737f8500bf74990e6b8dab refs/tags/0.23.0\nbd969ad3745db0d66022564cac76cf9424651104 refs/tags/0.23.1\na037c646a47623b92718efadc2bb74d03664b360 refs/tags/0.23.2\n078475ccceeaca0fac947492acdd24514da8d863 refs/tags/0.24.0\ne7bd87dc992512fd5825a557a56907647e03c979 refs/tags/0.24.1\n45ea601e1c7f64fb857bc99df984b86673621d2c refs/tags/0.3.0\n1ea9868a3fee3aa487ab7ec9129208a4dd483d0d refs/tags/0.4.0\n39afdb5733d3245386d29d08c5ff61c89268f499 refs/tags/0.5.0\n458c7b5910fcb157af3fc51bc3b3e663fdb3ed4a refs/tags/0.6.0\n06c38bd8563d822455bc237c2a98c153d938ed1b refs/tags/0.7.0\nf446b6056eef6d8dc9d8b47a79aca93d17dc8230 refs/tags/0.8.0\nbb25a195133f9f7af06386d0809793923cc5e8ab refs/tags/0.9.0\n"),
    toData("npeg", GitCurrentCommit, 0, "5d80f93aa720898936668b3bc47d0fff101ec414\n"),
    toData("npeg", GitMergeBase, 0, "5d80f93aa720898936668b3bc47d0fff101ec414\na037c646a47623b92718efadc2bb74d03664b360\na037c646a47623b92718efadc2bb74d03664b360\n"),

    toData("testes", GitDiff, 0, ""),
    toData("testes", GitTags, 0, "3ce9b2968b5f644755a0ced1baa3eece88c2f12e refs/tags/0.1.0\nf73af8318b54737678fab8b54bdcd8a451015e0d refs/tags/0.1.1\nd21d84d37b161a123a43318bae353108755916de refs/tags/0.1.2\n5c36b6095353ed03b08ac939d00aff2d73f79a35 refs/tags/0.1.3\na1220d11237ee8f135f772ff9731c11b2d91ba31 refs/tags/0.1.4\n574f741b90d04a7ce8c9b990e6077708d7ad076e refs/tags/0.1.5\nced0a9e58234b680def6931578e09165a32e6291 refs/tags/0.1.6\nbb248952e8742a6011eb1a45a9d2059aeb0341d7 refs/tags/0.1.7\nabb7d7c552da0a8e0ddc586c15ccf7e74b0d068b refs/tags/0.10.0\n6e42a768a90d6442196b344bcdcb6f834b76e7b7 refs/tags/0.2.0\n9d136c3a0851ca2c021f5fb4f7b63f0a0ef77232 refs/tags/0.2.1\ndcb282b2da863fd2939e1969cec7a99788feb456 refs/tags/0.2.2\nf708a632afaa40a322a1a61c1c13722edac8e8c5 refs/tags/0.3.0\n3213f59e3f9ba052452c59f01d1418360d856af6 refs/tags/0.3.1\nf7bb1743dffd327958dfcebae4cfb6f61cc1cb8c refs/tags/0.3.2\n6b64569ebecad6bc60cc8697713701e7659204f4 refs/tags/0.3.3\nb51c25a4367bd17f419f78cb5a27f319e9d820f5 refs/tags/0.3.4\nb265612710cbd5ddb1b173c94ece8ec5c7ceccac refs/tags/0.3.5\ne404bcfe42e92d7509717a2dfa115cacb4964c5d refs/tags/0.3.6\n5e4d0d5b7e7f314dde701c546c4365c59782d3dc refs/tags/0.3.7\ne13f91c9c913d2b81c59adeaad687efa2b35293a refs/tags/0.3.8\n17599625f09af0ae4b525e63ab726a3002540702 refs/tags/0.3.9\n13e907f70571dd146d8dc29ddec4599b40ba4e85 refs/tags/0.4.0\n155a74cf676495df1e0674dd07b5e4a0291a9a4a refs/tags/0.4.1\nf37abccdc148cb02ca637a6f0bc8821491cce358 refs/tags/0.4.2\n0250d29ebdd02f28f9020445adb5a4e51fd1902c refs/tags/0.5.0\n2fb87db6d9f34109a70205876030c53f815739b7 refs/tags/0.5.1\n629d17ba8d6a1a4eca8145eb089ed5bca4473dfc refs/tags/0.6.0\ne926130f5f1b7903f68be49cc1563225bd9d948d refs/tags/0.7.0\n7365303897e6185796c274425c079916047e3f14 refs/tags/0.7.1\na735c4adabeba637409f41c4325dd8fc5fb91e2d refs/tags/0.7.10\nfe023fd27404889c5122f902456cbba14b767405 refs/tags/0.7.11\n4430e72972c77a5e9c1555d59bba11d840682691 refs/tags/0.7.12\nf0e53eb490a9558c7f594d2e095b70665e36ca88 refs/tags/0.7.13\nf6520e25e7c329c2957cda447f149fc6a930db0d refs/tags/0.7.2\nd509762f7191757c240d3c79c9ecda53f8c0cfe3 refs/tags/0.7.3\nc02e7a783d1c42fd1f91bca7142f7c3733950c05 refs/tags/0.7.4\n8c8a9e496e9b86ba7602709438980ca31e6989d9 refs/tags/0.7.5\n29839c18b4ac83c0111a178322b57ebb8a8d402c refs/tags/0.7.6\n3b62973cf74fafd8ea906644d89ac34d29a8a6cf refs/tags/0.7.7\ne67ff99dc43c391e89a37f97a9d298c3428bbde2 refs/tags/0.7.8\n4b72ecda0d40ed8e5ab8ad4095a0691d30ec6cd0 refs/tags/0.7.9\n2512b8cc3d7f001d277e89978da2049a5feee5c4 refs/tags/0.8.0\n86c47029690bd2731d204245f3f54462227bba0d refs/tags/0.9.0\n9a7f94f78588e9b5ba7ca077e1f7eae0607c6cf6 refs/tags/0.9.1\n08c915dc016d16c1dfa9a77d0b045ec29c9f2074 refs/tags/0.9.2\n3fb658b1ce1e1efa37d6f9f14322bdac8def02a5 refs/tags/0.9.3\n738fda0add962379ffe6aa6ca5f01a6943a98a2e refs/tags/0.9.4\n48d821add361f7ad768ecb35a0b19c38f90c919e refs/tags/0.9.5\nff9ae890f597dac301b2ac6e6805eb9ac5afd49a refs/tags/0.9.6\n483c78f06e60b0ec5e79fc3476df075ee7286890 refs/tags/0.9.7\n416eec87a5ae39a1a6035552e9e9a47d76b13026 refs/tags/1.0.0\na935cfe9445cc5218fbdd7e0afb35aa1587fff61 refs/tags/1.0.1\n4b83863a9181f054bb695b11b5d663406dfd85d2 refs/tags/1.0.2\n295145fddaa4fe29c1e71a5044d968a84f9dbf69 refs/tags/1.1.0\n8f74ea4e5718436c47305b4488842e6458a13dac refs/tags/1.1.1\n4135bb291e53d615a976e997c44fb2bd9e1ad343 refs/tags/1.1.10\n8c09dbcd16612f5989065db02ea2e7a752dd2656 refs/tags/1.1.11\naedfebdb6c016431d84b0c07cf181b957a900640 refs/tags/1.1.12\n2c2e958366ef6998115740bdf110588d730e5738 refs/tags/1.1.2\nbecc77258321e6ec40d89efdddf37bafd0d07fc3 refs/tags/1.1.3\ne070d7c9853bf94c35b81cf0c0a8980c2449bb22 refs/tags/1.1.4\n12c986cbbf65e8571a486e9230808bf887e5f04f refs/tags/1.1.5\n63df8986f5b56913b02d26954fa033eeaf43714c refs/tags/1.1.6\n38e02c9c6bd728b043036fe0d1894d774cab3108 refs/tags/1.1.7\n3c3879fff16450d28ade79a6b08982bf5cefc061 refs/tags/1.1.8\ne32b811b3b2e70a1d189d7a663bc2583e9c18f96 refs/tags/1.1.9\n0c1b4277c08197ce7e7e0aa2bad91d909fcd96ac refs/tags/2.0.0\n"),
    toData("testes", GitCurrentCommit, 0, "d9db2ad09aa38fc26625341e1b666602959e144f\n"),
    toData("testes", GitMergeBase, 0, "d9db2ad09aa38fc26625341e1b666602959e144f\n416eec87a5ae39a1a6035552e9e9a47d76b13026\nd9db2ad09aa38fc26625341e1b666602959e144f\n"),
    toData("testes", GitCheckout, 0, "416eec87a5ae39a1a6035552e9e9a47d76b13026"),

    toData("grok", GitDiff, 0, ""),
    toData("grok", GitTags, 0, "2ca193c31fa2377c1e991a080d60ca3215ff6cf0 refs/tags/0.0.1\n48007554b21ba2f65c726ae2fdda88d621865b4a refs/tags/0.0.2\n7092a0286421c7818cd335cca9ebc72d03d866c2 refs/tags/0.0.3\n62707b8ac684efac35d301dbde57dc750880268e refs/tags/0.0.4\n876f2504e0c2f785ffd2cf65a78e2aea474fa8aa refs/tags/0.0.5\nb7eb1f2501aa2382cb3a38353664a13af62a9888 refs/tags/0.0.6\nf5d818bfd6038884b3d8b531c58484ded20a58a4 refs/tags/0.1.0\n961eaddea49c3144d130d105195583d3f11fb6c6 refs/tags/0.2.0\n15ab8ed8d4f896232a976a9008548bd53af72a66 refs/tags/0.2.1\n426a7d7d4603f77ced658e73ad7f3f582413f6cd refs/tags/0.3.0\n83cf7a39b2fe897786fb0fe01a7a5933c3add286 refs/tags/0.3.1\n8d2e3c900edbc95fa0c036fd76f8e4f814aef2c1 refs/tags/0.3.2\n48b43372f49a3bb4dc0969d82a0fca183fb94662 refs/tags/0.3.3\n9ca947a3009ea6ba17814b20eb953272064eb2e6 refs/tags/0.4.0\n1b5643d04fba6d996a16d1ffc13d034a40003f8f refs/tags/0.5.0\n486b0eb580b1c465453d264ac758cc490c19c33e refs/tags/0.5.1\naedb0d9497390e20b9d2541cef2bb05a5cda7a71 refs/tags/0.5.2\n"),
    toData("grok", GitCurrentCommit, 0, "4e6526a91a23eaec778184e16ce9a34d25d48bdc\n"),
    toData("grok", GitMergeBase, 0, "4e6526a91a23eaec778184e16ce9a34d25d48bdc\n62707b8ac684efac35d301dbde57dc750880268e\n349c15fd1e03f1fcdd81a1edefba3fa6116ab911\n"),
    toData("grok", GitCheckout, 0, "62707b8ac684efac35d301dbde57dc750880268e"),

    toData("nim-bytes2human", GitDiff, 0, ""),
    toData("nim-bytes2human", GitTags, 0, ""),
    toData("nim-bytes2human", GitCurrentcommit, 0, "ec2c1a758cabdd4751a06c8ebf2b923f19e32731\n")
  ]

#[
Current directory is now E:\atlastest\nim-bytes2human
cmd git diff args [] --> ("", 0)
cmd git show-ref --tags args [] --> ("", 1)
cmd git log -n 1 --format=%H args [] --> (, 0)
[Warning] (nim-bytes2human) package has no tagged releases
nimble E:\atlastest\nim-bytes2human\bytes2human.nimble info (requires: @["nim >= 1.0.0"], srcDir: "src", tasks: @[])
[Error] There were problems.
Error: execution of an external program failed: 'E:\nim\tools\atlas\atlas.exe clone https://github.com/disruptek/balls'
]#
