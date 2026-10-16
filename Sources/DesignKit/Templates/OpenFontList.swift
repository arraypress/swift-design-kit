//
//  OpenFontList.swift
//  DesignKit
//
//  Created by David Sherlock on 2026.
//
//  The open fonts a design can name and have fetched on first use: every
//  one from the google/fonts repository's `ofl/` folder (SIL Open Font
//  License 1.1), pinned to one commit, each file's SHA-256 measured when
//  the list was made. Nothing here is bundled — the files are fetched into
//  the user's Application Support with their OFL.txt beside them.
//

extension OpenFonts {

    /// The google/fonts commit every file is fetched from.
    public static let commit = "9710da1eacb3be272583c3224dcb70f9da6eadbb"

    static let list: [OpenFont] = [
        OpenFont(family: "Playfair Display", folder: "playfairdisplay", category: .serif, files: [
            .init(name: "PlayfairDisplay[wght].ttf", sha256: "c40f2293766a503bc70cce9e512ef844a4ccb7cbcde792fe2ea31d191917d8d6", bytes: 300724),
            .init(name: "PlayfairDisplay-Italic[wght].ttf", sha256: "a5e26dc5e2e77fb2803a0bf02fd4f81ee136ec8dea863ccdb0c59a263b21378b", bytes: 278688),
            .init(name: "OFL.txt", sha256: "566be814f8e96e93dfa16101331557eb6b5467e9e03f627c0910fe93ca12300e", bytes: 4449),
        ]),
        OpenFont(family: "DM Serif Display", folder: "dmserifdisplay", category: .serif, files: [
            .init(name: "DMSerifDisplay-Regular.ttf", sha256: "8cc3643535edf039aa5d95440a8542735e9197e4f4b8d9303e980fefbf5ab616", bytes: 76580),
            .init(name: "DMSerifDisplay-Italic.ttf", sha256: "df74c0ac387baeaeb0fe4f2324e1668e6a3ed8c09cd9796fe162c71753e19e45", bytes: 71208),
            .init(name: "OFL.txt", sha256: "a3e5cdd67d4571dd0a24fcc968de0efde7ae97ef752daf0906e4767619dd7231", bytes: 4605),
        ]),
        OpenFont(family: "Fraunces", folder: "fraunces", category: .serif, files: [
            .init(name: "Fraunces[SOFT,WONK,opsz,wght].ttf", sha256: "177ff6c0f14e5550a3c624247cd1189611d4eb65d000b14944c63d967958abbb", bytes: 360440),
            .init(name: "Fraunces-Italic[SOFT,WONK,opsz,wght].ttf", sha256: "b24448c43702fac4ee856781d461a0dfba8d8e594b6e8e190234b75fed2c0e01", bytes: 414904),
            .init(name: "OFL.txt", sha256: "bdf4c22802eaf804f998195871c6b8938aac2ac14b2d78a8bd66a6f1eced833b", bytes: 4391),
        ]),
        OpenFont(family: "Bodoni Moda", folder: "bodonimoda", category: .serif, files: [
            .init(name: "BodoniModa[opsz,wght].ttf", sha256: "550f5e34ee0a828d7941b1fe9bc58b34e5260d3f33a61532e6d0a0114e79a5cf", bytes: 162104),
            .init(name: "BodoniModa-Italic[opsz,wght].ttf", sha256: "dfff1619f8f6871c6372f8855b67211f9a73b4e93d45aca868cd8f46a48622de", bytes: 176300),
            .init(name: "OFL.txt", sha256: "931dfe2e0cd3c9443295f5c1d754b8a8403bf060df50c1d5900267ade83d0046", bytes: 4400),
        ]),
        OpenFont(family: "Cormorant Garamond", folder: "cormorantgaramond", category: .serif, files: [
            .init(name: "CormorantGaramond[wght].ttf", sha256: "b20b7d9626dd956b2c5e558692ad328b1f19e3275e2782db4fa07670d83f35e0", bytes: 1195560),
            .init(name: "CormorantGaramond-Italic[wght].ttf", sha256: "0f48ea6abb2084537854f7174c470991a463b13036309e3b50a81511611c530d", bytes: 715644),
            .init(name: "OFL.txt", sha256: "60700d351cac4650c51f3f9db318d2a420f8b45052dba2715eb5fec41f0f6956", bytes: 4387),
        ]),
        OpenFont(family: "Instrument Serif", folder: "instrumentserif", category: .serif, files: [
            .init(name: "InstrumentSerif-Regular.ttf", sha256: "498efd461f6ddfcb7a111bf9a565709d2085d48201d501ead960d93e84ffbb88", bytes: 70012),
            .init(name: "InstrumentSerif-Italic.ttf", sha256: "08939b8bdf534afec24ae0ef5e03f948940cd9a8fe08e7fecbad040e62327385", bytes: 71592),
            .init(name: "OFL.txt", sha256: "129ed7618959716959f2941fdd5b49e0ad6e6c1d78726761786a00253d865521", bytes: 4405),
        ]),
        OpenFont(family: "Young Serif", folder: "youngserif", category: .serif, files: [
            .init(name: "YoungSerif-Regular.ttf", sha256: "42bb2602364b28569fdce5eeb6ab3d81cf8090ba81b211f1229ed69f33155523", bytes: 106608),
            .init(name: "OFL.txt", sha256: "737d8d343b674c6894f373de71a044b6782c130f2aebf180933d63ddf7a3dc19", bytes: 4398),
        ]),
        OpenFont(family: "Abril Fatface", folder: "abrilfatface", category: .display, files: [
            .init(name: "AbrilFatface-Regular.ttf", sha256: "5971d4a3758a922a9fedc7f6fb825a96341a2e718c45a4b2c9a6b417c8c4dbe9", bytes: 67364),
            .init(name: "OFL.txt", sha256: "aba8997e16b1e3888c6e855ba883c70d96bd4375bff8cb9c7ce0f097200f74b8", bytes: 4415),
        ]),
        OpenFont(family: "Bebas Neue", folder: "bebasneue", category: .display, files: [
            .init(name: "BebasNeue-Regular.ttf", sha256: "08e4623805102d819f58601e46e345648846075e363b2ceb23313c2d1c83ec73", bytes: 61400),
            .init(name: "OFL.txt", sha256: "72082f6cb4d04be2ecf7cc7d9e1e7d73787f0af8a5a278a47cade70c16b78341", bytes: 4337),
        ]),
        OpenFont(family: "Anton", folder: "anton", category: .display, files: [
            .init(name: "Anton-Regular.ttf", sha256: "a4ba3a92350ebb031da0cb47630ac49eb265082ca1bc0450442f4a83ab947cab", bytes: 170812),
            .init(name: "OFL.txt", sha256: "ee67e6ee22790b7929f1a3769ca2801d565c64b5a9096942c1adf5596de9c9e4", bytes: 4484),
        ]),
        OpenFont(family: "Archivo Black", folder: "archivoblack", category: .display, files: [
            .init(name: "ArchivoBlack-Regular.ttf", sha256: "dd9a89a019b4849f66ab75455fe7bdf931311042cbb0f0f97acc061539703180", bytes: 90988),
            .init(name: "OFL.txt", sha256: "3173acd82f8c6159b5b1037b539fcbd4edff68e65c2ea8b9412b5a5ca97b08ff", bytes: 4492),
        ]),
        OpenFont(family: "Oswald", folder: "oswald", category: .sans, files: [
            .init(name: "Oswald[wght].ttf", sha256: "5b38c246e255a12f5712d640d56bcced0472466fc68983d2d0410ec0457c2817", bytes: 172088),
            .init(name: "OFL.txt", sha256: "0fd731a904b729a4e02eaf5e8ebd06783edd9abe400e8882760160230675b652", bytes: 4483),
        ]),
        OpenFont(family: "Space Grotesk", folder: "spacegrotesk", category: .sans, files: [
            .init(name: "SpaceGrotesk[wght].ttf", sha256: "acad6de1fc93436f5c0f1f4137751ef04f1aea3063e7036535970ffcfbd79f72", bytes: 136676),
            .init(name: "OFL.txt", sha256: "564ce565c371c5e5bbf286006565a7c9aa55a9f56e7ca58d56e05d649dd61a72", bytes: 4495),
        ]),
        OpenFont(family: "Syne", folder: "syne", category: .sans, files: [
            .init(name: "Syne[wght].ttf", sha256: "ce5ac77142a65cab2248a1a2ebb740b1d4d9c20b52488877d3ff664d1356104a", bytes: 146980),
            .init(name: "OFL.txt", sha256: "cc43cdce6f91c57989af8459341c276655e34224e954fa69c2ad700831a742d8", bytes: 4402),
        ]),
        OpenFont(family: "Unbounded", folder: "unbounded", category: .display, files: [
            .init(name: "Unbounded[wght].ttf", sha256: "323b511be380c8d474ef030686b71aedde501f8d9cd46da558b7c40454372c3f", bytes: 778272),
            .init(name: "OFL.txt", sha256: "31e5d4e83955e7103c34570dd49b0570ef490800bd65b42923c0dd02445263b3", bytes: 4392),
        ]),
        OpenFont(family: "Bricolage Grotesque", folder: "bricolagegrotesque", category: .sans, files: [
            .init(name: "BricolageGrotesque[opsz,wdth,wght].ttf", sha256: "413e7357809ddd12fd80a96a8a396de0e401638d4acd3cb3e37532f0472ac682", bytes: 408496),
            .init(name: "OFL.txt", sha256: "4b5a7d8f37f5602621c8a8d7358a6a2e71317e6c231c661e15aef0275d3e07ba", bytes: 4403),
        ]),
        OpenFont(family: "DM Sans", folder: "dmsans", category: .sans, files: [
            .init(name: "DMSans[opsz,wght].ttf", sha256: "8cd08d97e89c24d0aa92edd2f0f4c8ee6195eee9b7c9f154865a58b02f0c1c0d", bytes: 240164),
            .init(name: "DMSans-Italic[opsz,wght].ttf", sha256: "22259c0cc8237221b80f44c76ba8d36e6bce3cda72779f5b2773643d499720ae", bytes: 285040),
            .init(name: "OFL.txt", sha256: "9af36190332437f5ecd09974de43c1f7c77a310a996cdd8ceb25628b458840e1", bytes: 4482),
        ]),
        OpenFont(family: "Work Sans", folder: "worksans", category: .sans, files: [
            .init(name: "WorkSans[wght].ttf", sha256: "f50f61f2ba738e239442d40bf1069adb195c224b6a5a73a581fc2f3ed62a9f63", bytes: 361072),
            .init(name: "WorkSans-Italic[wght].ttf", sha256: "0a9f935ea490d3477fc97e40248f356c29bce11a1973939056c4316b122341ec", bytes: 336756),
            .init(name: "OFL.txt", sha256: "749aca05078664ce682dce1b1b10096ac397cb088c1a6df4e1bb56f0092a9272", bytes: 4396),
        ]),
        OpenFont(family: "Manrope", folder: "manrope", category: .sans, files: [
            .init(name: "Manrope[wght].ttf", sha256: "3ae11c49db0455a3cc33e37d380f20fdb8c7f8b41dc07625c177e3d87a9d6ae6", bytes: 164700),
            .init(name: "OFL.txt", sha256: "58172e0c0fac2cda8a37b348164bb55e44b0e69051e557e92b1d3f6910141f7b", bytes: 4387),
        ]),
        OpenFont(family: "Instrument Sans", folder: "instrumentsans", category: .sans, files: [
            .init(name: "InstrumentSans[wdth,wght].ttf", sha256: "b24f1812584816958afcf22e22d08e44318c5e51651e25d2438efdde389b33b1", bytes: 194336),
            .init(name: "InstrumentSans-Italic[wdth,wght].ttf", sha256: "a74203cc5066a3b2f8de1a7b0887ef897773c2319dc86c911f8e85350cde0d07", bytes: 202128),
            .init(name: "OFL.txt", sha256: "9e27a72ed30eb49a08678f6a5d6ed98ec7ba5368f541637ee0683ec9134ef966", bytes: 4403),
        ]),
        OpenFont(family: "EB Garamond", folder: "ebgaramond", category: .serif, files: [
            .init(name: "EBGaramond[wght].ttf", sha256: "ef9512f92f6d579e5dc75af59a5a4b1b8b47d2eda89e00b954d44520e5369027", bytes: 851176),
            .init(name: "EBGaramond-Italic[wght].ttf", sha256: "bba2c4499c93c9612b90b9825d32b07da52fce2fe57562a1eb6b833553f93c4e", bytes: 754468),
            .init(name: "OFL.txt", sha256: "0985066662eb755ed3683ae5482a81a9195b49ce3f7e165cc2388b3dbece7dd7", bytes: 4398),
        ]),
        OpenFont(family: "Lora", folder: "lora", category: .serif, files: [
            .init(name: "Lora[wght].ttf", sha256: "822a6621ccbe8d97d20ac88c1c41f5615c9c2c202eaa75f272cd452aac6475a7", bytes: 212196),
            .init(name: "Lora-Italic[wght].ttf", sha256: "22d8d8854b53807aa664ca34f2031a9ed57a1d0dea296b8b96cdd3aad937a2b3", bytes: 221232),
            .init(name: "OFL.txt", sha256: "1d9a970809ac804b582a6ce7f0ebc4e7fefcbfd7ff6299cad35ee656a21be716", bytes: 4423),
        ]),
        OpenFont(family: "Libre Baskerville", folder: "librebaskerville", category: .serif, files: [
            .init(name: "LibreBaskerville[wght].ttf", sha256: "05a95421961341c5b2556285e8415df9db27dab4f4abe22b446b3c6a8b916c5d", bytes: 171900),
            .init(name: "LibreBaskerville-Italic[wght].ttf", sha256: "223959683dc73ec4437bd61fabaa4b3f22209e22855ffd3aee36ba61a5116e97", bytes: 167456),
            .init(name: "OFL.txt", sha256: "3624eddd4c8f8a908130a417ae7cd089c9da69899c4e0ca1a5217d0a6fae16fd", bytes: 4542),
        ]),
        OpenFont(family: "Space Mono", folder: "spacemono", category: .mono, files: [
            .init(name: "SpaceMono-Regular.ttf", sha256: "95837e182baeeada83368f7748db28357f0a1b75c6b84ff7065b5edf933c8e18", bytes: 99356),
            .init(name: "SpaceMono-Bold.ttf", sha256: "405e73d41afb7e5906efce206a326af5c956f38e255f35421c260e861e599c59", bytes: 98232),
            .init(name: "SpaceMono-Italic.ttf", sha256: "eca264c8690a91fe837d19a6badf2d88961610c4c8aafcb196526192a9f258c5", bytes: 121396),
            .init(name: "SpaceMono-BoldItalic.ttf", sha256: "cdcc95eddee312879a9728494e595f591cb159f3f276d79bc58673dec7e57138", bytes: 111904),
            .init(name: "OFL.txt", sha256: "8e4ee42b2553e1e01504e61cb0d46d148cd8c9e5eacaa3622a7df2d4f2955b9f", bytes: 4392),
        ]),
        OpenFont(family: "DM Mono", folder: "dmmono", category: .mono, files: [
            .init(name: "DMMono-Light.ttf", sha256: "c7b3645dc8d28237317b4d017bc47b9ff09a7660758122dacb694a5a82552c24", bytes: 49752),
            .init(name: "DMMono-Regular.ttf", sha256: "55b4c98f123daebb3ed27947ba47b2af00554fc6284d639a540bcef5e6258ad2", bytes: 49744),
            .init(name: "DMMono-Medium.ttf", sha256: "fd327daf461db87b44a87def475d251bf03b997f7c07d9680592d75dbbfaad0b", bytes: 50360),
            .init(name: "DMMono-Italic.ttf", sha256: "32b5bad9cbce64eac6d05c8abbeb619317f7e4cb354e1c33db761adbfaae1b16", bytes: 51408),
            .init(name: "OFL.txt", sha256: "2bada5ea45c3c63b7f1ea1f88ce9672c9e4f0c42b2c3b7378949084fe55a3066", bytes: 4484),
        ]),
        OpenFont(family: "Righteous", folder: "righteous", category: .display, files: [
            .init(name: "Righteous-Regular.ttf", sha256: "2ffb3fe5c27d7e6571210b800448c4e234e651b46c6b4426c1bb567e5341348a", bytes: 43104),
            .init(name: "OFL.txt", sha256: "1c5bc055869d5e9151ec7774082727db720ec4293c65be67f91a4bdcaeb02998", bytes: 4432),
        ]),
        OpenFont(family: "Shrikhand", folder: "shrikhand", category: .display, files: [
            .init(name: "Shrikhand-Regular.ttf", sha256: "8ba32f6d6a96fb8dbc92fc1acfbc4d2123d5348063d89b2c3dd784e7afcb81af", bytes: 220804),
            .init(name: "OFL.txt", sha256: "325e890b8b26fe0a683c3ba24c506d902bdd7034d9c47bd7fa2bb72b5433b9c9", bytes: 4463),
        ]),
        OpenFont(family: "Rubik Mono One", folder: "rubikmonoone", category: .display, files: [
            .init(name: "RubikMonoOne-Regular.ttf", sha256: "b22624b6a36e543e942106edfccd198c50b57b65b924bfe02a6f0a5699429e6b", bytes: 141088),
            .init(name: "OFL.txt", sha256: "43d530580461a574f6dfed9e15af6a74e95f7c04d9bfa1174a63ff036e8eee07", bytes: 4462),
        ]),
        OpenFont(family: "Bungee", folder: "bungee", category: .display, files: [
            .init(name: "Bungee-Regular.ttf", sha256: "c4f5361ce120af3e6b9156d0bf379fa19cda2ea0cd18ac01fd99596c6bf66e3f", bytes: 118996),
            .init(name: "OFL.txt", sha256: "d5787a50dde5be6c6daecab9ed459939b1bc37cff0d0e00257eaf1ec2cf4c16c", bytes: 4473),
        ]),
        OpenFont(family: "Monoton", folder: "monoton", category: .display, files: [
            .init(name: "Monoton-Regular.ttf", sha256: "951c4cea65ffede784a7c9672feec5d329a7e1e12216c42d53ecf36c90d04dea", bytes: 51604),
            .init(name: "OFL.txt", sha256: "585c6d2da8bcd8ffa651e0016f2e992a6891b625143a46a1dacf00699a817d9a", bytes: 4401),
        ]),
        OpenFont(family: "Pacifico", folder: "pacifico", category: .script, files: [
            .init(name: "Pacifico-Regular.ttf", sha256: "5b6c0d5334a7bf77dea52b975c5a0c408878c0f7115ed5b6fb151f634b7bf701", bytes: 329380),
            .init(name: "OFL.txt", sha256: "a47e5daeda73568969395c656823102678f2eefb0d7d7ecb47aac4cc17e42204", bytes: 4389),
        ]),
    ]
}
