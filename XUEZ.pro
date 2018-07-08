TEMPLATE = app
TARGET = xuez-qt
VERSION = 1.0.1.10
INCLUDEPATH += src src/json src/qt src/qt/plugins/mrichtexteditor
QT += network printsupport
DEFINES += ENABLE_WALLET
DEFINES += BOOST_THREAD_USE_LIB BOOST_SPIRIT_THREADSAFE
CONFIG += no_include_pwd
CONFIG += thread
CONFIG += static
#CONFIG += openssl-linked
CONFIG += openssl

greaterThan(QT_MAJOR_VERSION, 4) {
    QT += widgets
    DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0
}

# for boost 1.37, add -mt to the boost libraries
# use: qmake BOOST_LIB_SUFFIX=-mt
# for boost thread win32 with _win32 sufix
# use: BOOST_THREAD_LIB_SUFFIX=_win32-...
# or when linking against a specific BerkelyDB version: BDB_LIB_SUFFIX=-4.8

# Dependency library locations can be customized with:
#    BOOST_INCLUDE_PATH, BOOST_LIB_PATH, BDB_INCLUDE_PATH,
#    BDB_LIB_PATH, OPENSSL_INCLUDE_PATH and OPENSSL_LIB_PATH respectively

# workaround for boost 1.58
DEFINES += BOOST_VARIANT_USE_RELAXED_GET_BY_DEFAULT

win32:BOOST_LIB_SUFFIX=-mgw49-mt-s-1_57
win32:BOOST_INCLUDE_PATH=d:/project/crave/include/boost-1_57
win32:BOOST_LIB_PATH=d:/project/crave/lib
win32:BDB_INCLUDE_PATH=d:/project/crave/include/
win32:BDB_LIB_PATH=d:/project/crave/lib
win32:OPENSSL_INCLUDE_PATH=d:/project/crave/include/
win32:OPENSSL_LIB_PATH=d:/project/crave/lib
win32:MINIUPNPC_INCLUDE_PATH=d:/project/crave/include/
win32:MINIUPNPC_LIB_PATH=d:/project/crave/lib
win32:LIBPNG_INCLUDE_PATH=d:/project/crave/include/
win32:LIBPNG_LIB_PATH=d:/project/crave/lib
win32:QRENCODE_INCLUDE_PATH=d:/project/crave/include/
win32:QRENCODE_LIB_PATH=d:/project/crave/lib
win32:SECP256K1_LIB_PATH = d:/project/crave/include/
win32:SECP256K1_INCLUDE_PATH = d:/project/crave/lib

OBJECTS_DIR = build
MOC_DIR = build
UI_DIR = build

# use: qmake "RELEASE=1"
contains(RELEASE, 1) {
    macx:QMAKE_CXXFLAGS += -mmacosx-version-min=10.9 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.13.sdk
    macx:QMAKE_CFLAGS += -mmacosx-version-min=10.9 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.13.sdk
    macx:QMAKE_LFLAGS += -mmacosx-version-min=10.9 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.13.sdk
    macx:QMAKE_OBJECTIVE_CFLAGS += -mmacosx-version-min=10.9 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.13.sdk


    !windows:!macx {
        # Linux: static link
        # LIBS += -Wl,-Bstatic
    }
}

!win32 {
# for extra security against potential buffer overflows: enable GCCs Stack Smashing Protection
QMAKE_CXXFLAGS *= -fstack-protector-all --param ssp-buffer-size=1
QMAKE_LFLAGS *= -fstack-protector-all --param ssp-buffer-size=1
# We need to exclude this for Windows cross compile with MinGW 4.2.x, as it will result in a non-working executable!
# This can be enabled for Windows, when we switch to MinGW >= 4.4.x.
}
# for extra security (see: https://wiki.debian.org/Hardening): this flag is GCC compiler-specific
QMAKE_CXXFLAGS *= -D_FORTIFY_SOURCE=2
# for extra security on Windows: enable ASLR and DEP via GCC linker flags
win32:QMAKE_LFLAGS *= -Wl,--dynamicbase -Wl,--nxcompat
# on Windows: enable GCC large address aware linker flag
win32:QMAKE_LFLAGS *= -Wl,--large-address-aware -static
# i686-w64-mingw32
win32:QMAKE_LFLAGS *= -static-libgcc -static-libstdc++

# use: qmake "USE_QRCODE=1"
# libqrencode (http://fukuchi.org/works/qrencode/index.en.html) must be installed for support
contains(USE_QRCODE, 1) {
    message(Building with QRCode support)
    DEFINES += USE_QRCODE
    LIBS += -lqrencode
}


# use: qmake "USE_DBUS=1" or qmake "USE_DBUS=0"
linux:count(USE_DBUS, 0) {
    USE_DBUS=1
}
contains(USE_DBUS, 1) {
    message(Building with DBUS (Freedesktop notifications) support)
    DEFINES += USE_DBUS
    QT += dbus
}

contains(BITCOIN_NEED_QT_PLUGINS, 1) {
    DEFINES += BITCOIN_NEED_QT_PLUGINS
    QTPLUGIN += qcncodecs qjpcodecs qtwcodecs qkrcodecs qtaccessiblewidgets
}


#Build Leveldb
INCLUDEPATH += src/leveldb/include src/leveldb/helpers
LIBS += $$PWD/src/leveldb/libleveldb.a $$PWD/src/leveldb/libmemenv.a
SOURCES += src/txdb-leveldb.cpp
!win32 {
    # we use QMAKE_CXXFLAGS_RELEASE even without RELEASE=1 because we use RELEASE to indicate linking preferences not -O preferences
    genleveldb.commands = cd $$PWD/src/leveldb && CC=$$QMAKE_CC CXX=$$QMAKE_CXX $(MAKE) OPT=\"$$QMAKE_CXXFLAGS $$QMAKE_CXXFLAGS_RELEASE\" libleveldb.a libmemenv.a
} else {
    # make an educated guess about what the ranlib command is called
    isEmpty(QMAKE_RANLIB) {
        QMAKE_RANLIB = $$replace(QMAKE_STRIP, strip, ranlib)
    }
    LIBS += -lshlwapi
    #genleveldb.commands = cd $$PWD/src/leveldb && CC=$$QMAKE_CC CXX=$$QMAKE_CXX TARGET_OS=OS_WINDOWS_CROSSCOMPILE $(MAKE) OPT=\"$$QMAKE_CXXFLAGS $$QMAKE_CXXFLAGS_RELEASE\" libleveldb.a libmemenv.a && $$QMAKE_RANLIB $$PWD/src/leveldb/libleveldb.a && $$QMAKE_RANLIB $$PWD/src/leveldb/libmemenv.a
}
genleveldb.target = $$PWD/src/leveldb/libleveldb.a
genleveldb.depends = FORCE
PRE_TARGETDEPS += $$PWD/src/leveldb/libleveldb.a
QMAKE_EXTRA_TARGETS += genleveldb
# Gross ugly hack that depends on qmake internals, unfortunately there is no other way to do it.
QMAKE_CLEAN += $$PWD/src/leveldb/libleveldb.a; cd $$PWD/src/leveldb ; $(MAKE) clean


#Build Secp256k1
!win32 {
INCLUDEPATH += src/secp256k1/include
LIBS += $$PWD/src/secp256k1/src/libsecp256k1_la-secp256k1.o
    # we use QMAKE_CXXFLAGS_RELEASE even without RELEASE=1 because we use RELEASE to indicate linking preferences not -O preferences
    gensecp256k1.commands = cd $$PWD/src/secp256k1 && ./autogen.sh && ./configure --enable-module-recovery && CC=$$QMAKE_CC CXX=$$QMAKE_CXX $(MAKE) OPT=\"$$QMAKE_CXXFLAGS $$QMAKE_CXXFLAGS_RELEASE\"
    gensecp256k1.target = $$PWD/src/secp256k1/src/libsecp256k1_la-secp256k1.o
    gensecp256k1.depends = FORCE
    PRE_TARGETDEPS += $$PWD/src/secp256k1/src/libsecp256k1_la-secp256k1.o
    QMAKE_EXTRA_TARGETS += gensecp256k1
    # Gross ugly hack that depends on qmake internals, unfortunately there is no other way to do it.
    QMAKE_CLEAN += $$PWD/src/secp256k1/src/libsecp256k1_la-secp256k1.o; cd $$PWD/src/secp256k1; $(MAKE) clean
} else {
    isEmpty(SECP256K1_LIB_PATH) {
        windows:SECP256K1_LIB_PATH=C:/dev/coindeps32/Secp256k1/lib
    }
    isEmpty(SECP256K1_INCLUDE_PATH) {
        windows:SECP256K1_INCLUDE_PATH=C:/dev/coindeps32/Secp256k1/include
    }
}

# regenerate src/build.h
!windows|contains(USE_BUILD_INFO, 1) {
    genbuild.depends = FORCE
    genbuild.commands = cd $$PWD; /bin/sh share/genbuild.sh $$OUT_PWD/build/build.h
    genbuild.target = $$OUT_PWD/build/build.h
    PRE_TARGETDEPS += $$OUT_PWD/build/build.h
    QMAKE_EXTRA_TARGETS += genbuild
    DEFINES += HAVE_BUILD_INFO
}

contains(USE_O3, 1) {
    message(Building O3 optimization flag)
    QMAKE_CXXFLAGS_RELEASE -= -O2
    QMAKE_CFLAGS_RELEASE -= -O2
    QMAKE_CXXFLAGS += -O3
    QMAKE_CFLAGS += -O3
}

contains(USE_O0, 1) {
    message(Building O0 optimization flag)
    QMAKE_CXXFLAGS_RELEASE -= -O2
    QMAKE_CFLAGS_RELEASE -= -O2
    QMAKE_CXXFLAGS += -O0
    QMAKE_CFLAGS += -O0
}

*-g++-32 {
    message("32 platform, adding -msse2 flag")

    QMAKE_CXXFLAGS += -msse2
    QMAKE_CFLAGS += -msse2
}

QMAKE_CXXFLAGS_WARN_ON = -fdiagnostics-show-option -Wall -Wextra -Wno-ignored-qualifiers -Wformat -Wformat-security -Wno-unused-parameter -Wstack-protector
QMAKE_CXXFLAGS_WARN_ON += -Wno-unused-variable -fpermissive

windows:QMAKE_CXXFLAGS_WARN_ON += -Wno-cpp -Wno-maybe-uninitialized
!macx:QMAKE_CXXFLAGS_WARN_ON += -Wno-unused-local-typedefs
macx:QMAKE_CXXFLAGS_WARN_ON += -Wno-deprecated-declarations
# Input
HEADERS += src/accumulatormap.h \
           src/accumulators.h \
           src/activemasternode.h \
           src/addrman.h \
           src/alert.h \
           src/allocators.h \
           src/amount.h \
           src/arith_uint256.h \
           src/base58.h \
           src/bip38.h \
           src/bloom.h \
           src/chain.h \
           src/chainparams.h \
           src/chainparamsbase.h \
           src/chainparamsseeds.h \
           src/checkpoints.h \
           src/checkqueue.h \
           src/clientversion.h \
           src/coincontrol.h \
           src/coins.h \
           src/compat.h \
           src/compressor.h \
           src/core_io.h \
           src/crypter.h \
           src/db.h \
           src/denomination_functions.h \
           src/eccryptoverify.h \
           src/ecwrapper.h \
           src/hash.h \
           src/init.h \
           src/kernel.h \
           src/key.h \
           src/keystore.h \
           src/leveldbwrapper.h \
           src/limitedmap.h \
           src/main.h \
           src/masternode-budget.h \
           src/masternode-payments.h \
           src/masternode-sync.h \
           src/masternode.h \
           src/masternodeconfig.h \
           src/masternodeman.h \
           src/merkleblock.h \
           src/miner.h \
           src/mruset.h \
           src/net.h \
           src/netbase.h \
           src/noui.h \
           src/obfuscation-relay.h \
           src/obfuscation.h \
           src/pow.h \
           src/prevector.h \
           src/protocol.h \
           src/pubkey.h \
           src/random.h \
           src/reverse_iterate.h \
           src/rpcclient.h \
           src/rpcprotocol.h \
           src/rpcserver.h \
           src/serialize.h \
           src/spork.h \
           src/sporkdb.h \
           src/streams.h \
           src/swifttx.h \
           src/sync.h \
           src/threadsafety.h \
           src/timedata.h \
           src/tinyformat.h \
           src/torcontrol.h \
           src/txdb.h \
           src/txmempool.h \
           src/ui_interface.h \
           src/uint256.h \
           src/uint512.h \
           src/undo.h \
           src/util.h \
           src/utilmoneystr.h \
           src/utilstrencodings.h \
           src/utiltime.h \
           src/validationinterface.h \
           src/version.h \
           src/wallet.h \
           src/wallet_ismine.h \
           src/walletdb.h \
           src/compat/sanity.h \
           src/crypto/common.h \
           src/crypto/hmac_sha256.h \
           src/crypto/hmac_sha512.h \
           src/crypto/rfc6979_hmac_sha256.h \
           src/crypto/ripemd160.h \
           src/crypto/scrypt.h \
           src/crypto/sha1.h \
           src/crypto/sha256.h \
           src/crypto/sha512.h \
           src/crypto/sph_blake.h \
           src/crypto/sph_bmw.h \
           src/crypto/sph_cubehash.h \
           src/crypto/sph_echo.h \
           src/crypto/sph_fugue.h \
           src/crypto/sph_groestl.h \
           src/crypto/sph_hamsi.h \
           src/crypto/sph_haval.h \
           src/crypto/sph_jh.h \
           src/crypto/sph_keccak.h \
           src/crypto/sph_luffa.h \
           src/crypto/sph_sha2.h \
           src/crypto/sph_shabal.h \
           src/crypto/sph_shavite.h \
           src/crypto/sph_simd.h \
           src/crypto/sph_skein.h \
           src/crypto/sph_types.h \
           src/crypto/sph_whirlpool.h \
           src/json/json_spirit.h \
           src/json/json_spirit_error_position.h \
           src/json/json_spirit_reader.h \
           src/json/json_spirit_reader_template.h \
           src/json/json_spirit_stream_reader.h \
           src/json/json_spirit_utils.h \
           src/json/json_spirit_value.h \
           src/json/json_spirit_writer.h \
           src/json/json_spirit_writer_template.h \
           src/libzerocoin/Accumulator.h \
           src/libzerocoin/AccumulatorProofOfKnowledge.h \
           src/libzerocoin/bignum.h \
           src/libzerocoin/Coin.h \
           src/libzerocoin/CoinSpend.h \
           src/libzerocoin/Commitment.h \
           src/libzerocoin/Denominations.h \
           src/libzerocoin/ParamGeneration.h \
           src/libzerocoin/Params.h \
           src/libzerocoin/SerialNumberSignatureOfKnowledge.h \
           src/libzerocoin/ZerocoinDefines.h \
           src/primitives/block.h \
           src/primitives/transaction.h \
           src/primitives/zerocoin.h \
           src/qt/addressbookpage.h \
           src/qt/addresstablemodel.h \
           src/qt/askpassphrasedialog.h \
           src/qt/bip38tooldialog.h \
           src/qt/bitcoinaddressvalidator.h \
           src/qt/bitcoinamountfield.h \
           src/qt/bitcoingui.h \
           src/qt/bitcoinunits.h \
           src/qt/blockexplorer.h \
           src/qt/clientmodel.h \
           src/qt/coincontroldialog.h \
           src/qt/coincontroltreewidget.h \
           src/qt/csvmodelwriter.h \
           src/qt/editaddressdialog.h \
           src/qt/guiconstants.h \
           src/qt/guiutil.h \
           src/qt/intro.h \
           src/qt/macdockiconhandler.h \
           src/qt/macnotificationhandler.h \
           src/qt/masternodelist.h \
           src/qt/multisenddialog.h \
           src/qt/multisigdialog.h \
           src/qt/networkstyle.h \
           src/qt/notificator.h \
           src/qt/obfuscationconfig.h \
           src/qt/openuridialog.h \
           src/qt/optionsdialog.h \
           src/qt/optionsmodel.h \
           src/qt/overviewpage.h \
           src/qt/paymentrequestplus.h \
           src/qt/paymentserver.h \
           src/qt/peertablemodel.h \
           src/qt/platformstyle.h \
           src/qt/privacydialog.h \
           src/qt/qvalidatedlineedit.h \
           src/qt/qvaluecombobox.h \
           src/qt/receivecoinsdialog.h \
           src/qt/receiverequestdialog.h \
           src/qt/recentrequeststablemodel.h \
           src/qt/rpcconsole.h \
           src/qt/sendcoinsdialog.h \
           src/qt/sendcoinsentry.h \
           src/qt/signverifymessagedialog.h \
           src/qt/splashscreen.h \
           src/qt/trafficgraphwidget.h \
           src/qt/transactiondesc.h \
           src/qt/transactiondescdialog.h \
           src/qt/transactionfilterproxy.h \
           src/qt/transactionrecord.h \
           src/qt/transactiontablemodel.h \
           src/qt/transactionview.h \
           src/qt/utilitydialog.h \
           src/qt/walletframe.h \
           src/qt/walletmodel.h \
           src/qt/walletmodeltransaction.h \
           src/qt/walletview.h \
           src/qt/winshutdownmonitor.h \
           src/qt/zxuezcontroldialog.h \
           src/script/bitcoinconsensus.h \
           src/script/interpreter.h \
           src/script/script.h \
           src/script/script_error.h \
           src/script/sigcache.h \
           src/script/sign.h \
           src/script/standard.h \
           src/test/bignum.h \
           src/univalue/univalue.h \
           src/univalue/univalue_escapes.h \
           src/zmq/zmqabstractnotifier.h \
           src/zmq/zmqconfig.h \
           src/zmq/zmqnotificationinterface.h \
           src/zmq/zmqpublishnotifier.h \
           src/leveldb/db/builder.h \
           src/leveldb/db/db_impl.h \
           src/leveldb/db/db_iter.h \
           src/leveldb/db/dbformat.h \
           src/leveldb/db/filename.h \
           src/leveldb/db/log_format.h \
           src/leveldb/db/log_reader.h \
           src/leveldb/db/log_writer.h \
           src/leveldb/db/memtable.h \
           src/leveldb/db/skiplist.h \
           src/leveldb/db/snapshot.h \
           src/leveldb/db/table_cache.h \
           src/leveldb/db/version_edit.h \
           src/leveldb/db/version_set.h \
           src/leveldb/db/write_batch_internal.h \
           src/leveldb/port/atomic_pointer.h \
           src/leveldb/port/port.h \
           src/leveldb/port/port_example.h \
           src/leveldb/port/port_posix.h \
           src/leveldb/port/port_win.h \
           src/leveldb/port/thread_annotations.h \
           src/leveldb/table/block.h \
           src/leveldb/table/block_builder.h \
           src/leveldb/table/filter_block.h \
           src/leveldb/table/format.h \
           src/leveldb/table/iterator_wrapper.h \
           src/leveldb/table/merger.h \
           src/leveldb/table/two_level_iterator.h \
           src/leveldb/util/arena.h \
           src/leveldb/util/coding.h \
           src/leveldb/util/crc32c.h \
           src/leveldb/util/hash.h \
           src/leveldb/util/histogram.h \
           src/leveldb/util/logging.h \
           src/leveldb/util/mutexlock.h \
           src/leveldb/util/posix_logger.h \
           src/leveldb/util/random.h \
           src/leveldb/util/testharness.h \
           src/leveldb/util/testutil.h \
           src/qt/test/paymentrequestdata.h \
           src/qt/test/paymentservertests.h \
           src/qt/test/uritests.h \
           src/secp256k1/include/secp256k1.h \
           src/secp256k1/src/ecdsa.h \
           src/secp256k1/src/ecdsa_impl.h \
           src/secp256k1/src/eckey.h \
           src/secp256k1/src/eckey_impl.h \
           src/secp256k1/src/ecmult.h \
           src/secp256k1/src/ecmult_gen.h \
           src/secp256k1/src/ecmult_gen_impl.h \
           src/secp256k1/src/ecmult_impl.h \
           src/secp256k1/src/field.h \
           src/secp256k1/src/field_10x26.h \
           src/secp256k1/src/field_10x26_impl.h \
           src/secp256k1/src/field_5x52.h \
           src/secp256k1/src/field_5x52_asm_impl.h \
           src/secp256k1/src/field_5x52_impl.h \
           src/secp256k1/src/field_5x52_int128_impl.h \
           src/secp256k1/src/field_gmp.h \
           src/secp256k1/src/field_gmp_impl.h \
           src/secp256k1/src/field_impl.h \
           src/secp256k1/src/group.h \
           src/secp256k1/src/group_impl.h \
           src/secp256k1/src/num.h \
           src/secp256k1/src/num_gmp.h \
           src/secp256k1/src/num_gmp_impl.h \
           src/secp256k1/src/num_impl.h \
           src/secp256k1/src/scalar.h \
           src/secp256k1/src/scalar_4x64.h \
           src/secp256k1/src/scalar_4x64_impl.h \
           src/secp256k1/src/scalar_8x32.h \
           src/secp256k1/src/scalar_8x32_impl.h \
           src/secp256k1/src/scalar_impl.h \
           src/secp256k1/src/testrand.h \
           src/secp256k1/src/testrand_impl.h \
           src/secp256k1/src/util.h \
           src/leveldb/helpers/memenv/memenv.h \
           src/leveldb/include/leveldb/c.h \
           src/leveldb/include/leveldb/cache.h \
           src/leveldb/include/leveldb/comparator.h \
           src/leveldb/include/leveldb/db.h \
           src/leveldb/include/leveldb/dumpfile.h \
           src/leveldb/include/leveldb/env.h \
           src/leveldb/include/leveldb/filter_policy.h \
           src/leveldb/include/leveldb/iterator.h \
           src/leveldb/include/leveldb/options.h \
           src/leveldb/include/leveldb/slice.h \
           src/leveldb/include/leveldb/status.h \
           src/leveldb/include/leveldb/table.h \
           src/leveldb/include/leveldb/table_builder.h \
           src/leveldb/include/leveldb/write_batch.h \
           src/leveldb/port/win/stdint.h \
           src/secp256k1/src/java/org_bitcoin_NativeSecp256k1.h
FORMS += src/qt/forms/addressbookpage.ui \
         src/qt/forms/askpassphrasedialog.ui \
         src/qt/forms/bip38tooldialog.ui \
         src/qt/forms/blockexplorer.ui \
         src/qt/forms/coincontroldialog.ui \
         src/qt/forms/editaddressdialog.ui \
         src/qt/forms/helpmessagedialog.ui \
         src/qt/forms/intro.ui \
         src/qt/forms/masternodelist-orig.ui \
         src/qt/forms/masternodelist.ui \
         src/qt/forms/multisenddialog.ui \
         src/qt/forms/multisigdialog.ui \
         src/qt/forms/obfuscationconfig.ui \
         src/qt/forms/openuridialog.ui \
         src/qt/forms/optionsdialog.ui \
         src/qt/forms/overviewpage.ui \
         src/qt/forms/privacydialog.ui \
         src/qt/forms/receivecoinsdialog.ui \
         src/qt/forms/receiverequestdialog.ui \
         src/qt/forms/rpcconsole.ui \
         src/qt/forms/sendcoinsdialog.ui \
         src/qt/forms/sendcoinsentry.ui \
         src/qt/forms/signverifymessagedialog.ui \
         src/qt/forms/transactiondescdialog.ui \
         src/qt/forms/zxuezcontroldialog.ui
SOURCES += src/accumulatormap.cpp \
           src/accumulators.cpp \
           src/activemasternode.cpp \
           src/addrman.cpp \
           src/alert.cpp \
           src/allocators.cpp \
           src/amount.cpp \
           src/arith_uint256.cpp \
           src/base58.cpp \
           src/bip38.cpp \
           src/bloom.cpp \
           src/chain.cpp \
           src/chainparams.cpp \
           src/chainparamsbase.cpp \
           src/checkpoints.cpp \
           src/clientversion.cpp \
           src/coins.cpp \
           src/compressor.cpp \
           src/core_read.cpp \
           src/core_write.cpp \
           src/crypter.cpp \
           src/db.cpp \
           src/denomination_functions.cpp \
           src/eccryptoverify.cpp \
           src/ecwrapper.cpp \
           src/hash.cpp \
           src/init.cpp \
           src/kernel.cpp \
           src/key.cpp \
           src/keystore.cpp \
           src/leveldbwrapper.cpp \
           src/main.cpp \
           src/masternode-budget.cpp \
           src/masternode-payments.cpp \
           src/masternode-sync.cpp \
           src/masternode.cpp \
           src/masternodeconfig.cpp \
           src/masternodeman.cpp \
           src/merkleblock.cpp \
           src/miner.cpp \
           src/net.cpp \
           src/netbase.cpp \
           src/noui.cpp \
           src/obfuscation-relay.cpp \
           src/obfuscation.cpp \
           src/pow.cpp \
           src/protocol.cpp \
           src/pubkey.cpp \
           src/random.cpp \
           src/rest.cpp \
           src/rpcblockchain.cpp \
           src/rpcclient.cpp \
           src/rpcdump.cpp \
           src/rpcmasternode-budget.cpp \
           src/rpcmasternode.cpp \
           src/rpcmining.cpp \
           src/rpcmisc.cpp \
           src/rpcnet.cpp \
           src/rpcprotocol.cpp \
           src/rpcrawtransaction.cpp \
           src/rpcserver.cpp \
           src/rpcwallet.cpp \
           src/spork.cpp \
           src/sporkdb.cpp \
           src/swifttx.cpp \
           src/sync.cpp \
           src/timedata.cpp \
           src/torcontrol.cpp \
           src/txdb.cpp \
           src/txmempool.cpp \
           src/uint256.cpp \
           src/util.cpp \
           src/utilmoneystr.cpp \
           src/utilstrencodings.cpp \
           src/utiltime.cpp \
           src/validationinterface.cpp \
           src/wallet.cpp \
           src/wallet_ismine.cpp \
           src/walletdb.cpp \
           src/xuez-cli.cpp \
           src/xuez-tx.cpp \
           src/xuezd.cpp \
           src/compat/glibc_compat.cpp \
           src/compat/glibc_sanity.cpp \
           src/compat/glibcxx_compat.cpp \
           src/compat/glibcxx_sanity.cpp \
           src/compat/strnlen.cpp \
           src/crypto/aes_helper.c \
           src/crypto/blake.c \
           src/crypto/bmw.c \
           src/crypto/cubehash.c \
           src/crypto/echo.c \
           src/crypto/fugue.c \
           src/crypto/groestl.c \
           src/crypto/hamsi.c \
           src/crypto/hamsi_helper.c \
           src/crypto/haval.c \
           src/crypto/haval_helper.c \
           src/crypto/hmac_sha256.cpp \
           src/crypto/hmac_sha512.cpp \
           src/crypto/jh.c \
           src/crypto/keccak.c \
           src/crypto/luffa.c \
           src/crypto/md_helper.c \
           src/crypto/rfc6979_hmac_sha256.cpp \
           src/crypto/ripemd160.cpp \
           src/crypto/scrypt.cpp \
           src/crypto/sha1.cpp \
           src/crypto/sha2.c \
           src/crypto/sha256.cpp \
           src/crypto/sha512.cpp \
           src/crypto/shabal.c \
           src/crypto/shavite.c \
           src/crypto/simd.c \
           src/crypto/skein.c \
           src/crypto/sph_md_helper.c \
           src/crypto/sph_sha2big.c \
           src/crypto/whirlpool.c \
           src/json/json_spirit_reader.cpp \
           src/json/json_spirit_value.cpp \
           src/json/json_spirit_writer.cpp \
           src/libzerocoin/Accumulator.cpp \
           src/libzerocoin/AccumulatorProofOfKnowledge.cpp \
           src/libzerocoin/Coin.cpp \
           src/libzerocoin/CoinSpend.cpp \
           src/libzerocoin/Commitment.cpp \
           src/libzerocoin/Denominations.cpp \
           src/libzerocoin/paramgen.cpp \
           src/libzerocoin/ParamGeneration.cpp \
           src/libzerocoin/Params.cpp \
           src/libzerocoin/SerialNumberSignatureOfKnowledge.cpp \
           src/primitives/block.cpp \
           src/primitives/transaction.cpp \
           src/primitives/zerocoin.cpp \
           src/qt/addressbookpage.cpp \
           src/qt/addresstablemodel.cpp \
           src/qt/askpassphrasedialog.cpp \
           src/qt/bip38tooldialog.cpp \
           src/qt/bitcoinaddressvalidator.cpp \
           src/qt/bitcoinamountfield.cpp \
           src/qt/bitcoingui.cpp \
           src/qt/bitcoinunits.cpp \
           src/qt/blockexplorer.cpp \
           src/qt/clientmodel.cpp \
           src/qt/coincontroldialog.cpp \
           src/qt/coincontroltreewidget.cpp \
           src/qt/csvmodelwriter.cpp \
           src/qt/editaddressdialog.cpp \
           src/qt/guiutil.cpp \
           src/qt/intro.cpp \
           src/qt/masternodelist.cpp \
           src/qt/multisenddialog.cpp \
           src/qt/multisigdialog.cpp \
           src/qt/networkstyle.cpp \
           src/qt/notificator.cpp \
           src/qt/obfuscationconfig.cpp \
           src/qt/openuridialog.cpp \
           src/qt/optionsdialog.cpp \
           src/qt/optionsmodel.cpp \
           src/qt/overviewpage.cpp \
           src/qt/paymentrequestplus.cpp \
           src/qt/paymentserver.cpp \
           src/qt/peertablemodel.cpp \
           src/qt/platformstyle.cpp \
           src/qt/privacydialog.cpp \
           src/qt/qvalidatedlineedit.cpp \
           src/qt/qvaluecombobox.cpp \
           src/qt/receivecoinsdialog.cpp \
           src/qt/receiverequestdialog.cpp \
           src/qt/recentrequeststablemodel.cpp \
           src/qt/rpcconsole.cpp \
           src/qt/sendcoinsdialog.cpp \
           src/qt/sendcoinsentry.cpp \
           src/qt/signverifymessagedialog.cpp \
           src/qt/splashscreen.cpp \
           src/qt/trafficgraphwidget.cpp \
           src/qt/transactiondesc.cpp \
           src/qt/transactiondescdialog.cpp \
           src/qt/transactionfilterproxy.cpp \
           src/qt/transactionrecord.cpp \
           src/qt/transactiontablemodel.cpp \
           src/qt/transactionview.cpp \
           src/qt/utilitydialog.cpp \
           src/qt/walletframe.cpp \
           src/qt/walletmodel.cpp \
           src/qt/walletmodeltransaction.cpp \
           src/qt/walletview.cpp \
           src/qt/winshutdownmonitor.cpp \
           src/qt/xuez.cpp \
           src/qt/xuezstrings.cpp \
           src/qt/zxuezcontroldialog.cpp \
           src/script/bitcoinconsensus.cpp \
           src/script/interpreter.cpp \
           src/script/script.cpp \
           src/script/script_error.cpp \
           src/script/sigcache.cpp \
           src/script/sign.cpp \
           src/script/standard.cpp \
           src/test/accounting_tests.cpp \
           src/test/alert_tests.cpp \
           src/test/allocator_tests.cpp \
           src/test/arith_uint256_tests.cpp \
           src/test/base32_tests.cpp \
           src/test/base58_tests.cpp \
           src/test/base64_tests.cpp \
           src/test/benchmark_zerocoin.cpp \
           src/test/bip32_tests.cpp \
           src/test/bloom_tests.cpp \
           src/test/checkblock_tests.cpp \
           src/test/Checkpoints_tests.cpp \
           src/test/coins_tests.cpp \
           src/test/compress_tests.cpp \
           src/test/crypto_tests.cpp \
           src/test/DoS_tests.cpp \
           src/test/getarg_tests.cpp \
           src/test/hash_tests.cpp \
           src/test/key_tests.cpp \
           src/test/libzerocoin_tests.cpp \
           src/test/main_tests.cpp \
           src/test/mempool_tests.cpp \
           src/test/miner_tests.cpp \
           src/test/mruset_tests.cpp \
           src/test/multisig_tests.cpp \
           src/test/netbase_tests.cpp \
           src/test/pmt_tests.cpp \
           src/test/rpc_tests.cpp \
           src/test/rpc_wallet_tests.cpp \
           src/test/sanity_tests.cpp \
           src/test/script_P2SH_tests.cpp \
           src/test/script_tests.cpp \
           src/test/scriptnum_tests.cpp \
           src/test/serialize_tests.cpp \
           src/test/sighash_tests.cpp \
           src/test/sigopcount_tests.cpp \
           src/test/skiplist_tests.cpp \
           src/test/test_xuez.cpp \
           src/test/timedata_tests.cpp \
           src/test/torcontrol_tests.cpp \
           src/test/transaction_tests.cpp \
           src/test/tutorial_zerocoin.cpp \
           src/test/uint256_tests.cpp \
           src/test/univalue_tests.cpp \
           src/test/util_tests.cpp \
           src/test/wallet_tests.cpp \
           src/test/zerocoin_denomination_tests.cpp \
           src/test/zerocoin_implementation_tests.cpp \
           src/test/zerocoin_transactions_tests.cpp \
           src/univalue/gen.cpp \
           src/univalue/univalue.cpp \
           src/univalue/univalue_read.cpp \
           src/univalue/univalue_write.cpp \
           src/zmq/zmqabstractnotifier.cpp \
           src/zmq/zmqnotificationinterface.cpp \
           src/zmq/zmqpublishnotifier.cpp \
           src/leveldb/db/autocompact_test.cc \
           src/leveldb/db/builder.cc \
           src/leveldb/db/c.cc \
           src/leveldb/db/c_test.c \
           src/leveldb/db/corruption_test.cc \
           src/leveldb/db/db_bench.cc \
           src/leveldb/db/db_impl.cc \
           src/leveldb/db/db_iter.cc \
           src/leveldb/db/db_test.cc \
           src/leveldb/db/dbformat.cc \
           src/leveldb/db/dbformat_test.cc \
           src/leveldb/db/dumpfile.cc \
           src/leveldb/db/filename.cc \
           src/leveldb/db/filename_test.cc \
           src/leveldb/db/leveldb_main.cc \
           src/leveldb/db/log_reader.cc \
           src/leveldb/db/log_test.cc \
           src/leveldb/db/log_writer.cc \
           src/leveldb/db/memtable.cc \
           src/leveldb/db/repair.cc \
           src/leveldb/db/skiplist_test.cc \
           src/leveldb/db/table_cache.cc \
           src/leveldb/db/version_edit.cc \
           src/leveldb/db/version_edit_test.cc \
           src/leveldb/db/version_set.cc \
           src/leveldb/db/version_set_test.cc \
           src/leveldb/db/write_batch.cc \
           src/leveldb/db/write_batch_test.cc \
           src/leveldb/issues/issue178_test.cc \
           src/leveldb/issues/issue200_test.cc \
           src/leveldb/port/port_posix.cc \
           src/leveldb/port/port_win.cc \
           src/leveldb/table/block.cc \
           src/leveldb/table/block_builder.cc \
           src/leveldb/table/filter_block.cc \
           src/leveldb/table/filter_block_test.cc \
           src/leveldb/table/format.cc \
           src/leveldb/table/iterator.cc \
           src/leveldb/table/merger.cc \
           src/leveldb/table/table.cc \
           src/leveldb/table/table_builder.cc \
           src/leveldb/table/table_test.cc \
           src/leveldb/table/two_level_iterator.cc \
           src/leveldb/util/arena.cc \
           src/leveldb/util/arena_test.cc \
           src/leveldb/util/bloom.cc \
           src/leveldb/util/bloom_test.cc \
           src/leveldb/util/cache.cc \
           src/leveldb/util/cache_test.cc \
           src/leveldb/util/coding.cc \
           src/leveldb/util/coding_test.cc \
           src/leveldb/util/comparator.cc \
           src/leveldb/util/crc32c.cc \
           src/leveldb/util/crc32c_test.cc \
           src/leveldb/util/env.cc \
           src/leveldb/util/env_posix.cc \
           src/leveldb/util/env_test.cc \
           src/leveldb/util/env_win.cc \
           src/leveldb/util/filter_policy.cc \
           src/leveldb/util/hash.cc \
           src/leveldb/util/hash_test.cc \
           src/leveldb/util/histogram.cc \
           src/leveldb/util/logging.cc \
           src/leveldb/util/options.cc \
           src/leveldb/util/status.cc \
           src/leveldb/util/testharness.cc \
           src/leveldb/util/testutil.cc \
           src/qt/test/paymentservertests.cpp \
           src/qt/test/test_main.cpp \
           src/qt/test/uritests.cpp \
           src/secp256k1/src/bench_inv.c \
           src/secp256k1/src/bench_sign.c \
           src/secp256k1/src/bench_verify.c \
           src/secp256k1/src/secp256k1.c \
           src/secp256k1/src/tests.c \
           src/leveldb/doc/bench/db_bench_sqlite3.cc \
           src/leveldb/doc/bench/db_bench_tree_db.cc \
           src/leveldb/helpers/memenv/memenv.cc \
           src/leveldb/helpers/memenv/memenv_test.cc \
           src/secp256k1/src/java/org_bitcoin_NativeSecp256k1.c
RESOURCES += src/qt/xuez.qrc src/qt/xuez_locale.qrc
TRANSLATIONS += src/qt/locale/xuez_bg.ts \
                src/qt/locale/xuez_ca.ts \
                src/qt/locale/xuez_cs.ts \
                src/qt/locale/xuez_da.ts \
                src/qt/locale/xuez_de.ts \
                src/qt/locale/xuez_en.ts \
                src/qt/locale/xuez_en_US.ts \
                src/qt/locale/xuez_es.ts \
                src/qt/locale/xuez_fi.ts \
                src/qt/locale/xuez_fr_FR.ts \
                src/qt/locale/xuez_hr.ts \
                src/qt/locale/xuez_it.ts \
                src/qt/locale/xuez_ja.ts \
                src/qt/locale/xuez_ko_KR.ts \
                src/qt/locale/xuez_nl.ts \
                src/qt/locale/xuez_pl.ts \
                src/qt/locale/xuez_pt.ts \
                src/qt/locale/xuez_pt_BR.ts \
                src/qt/locale/xuez_ro_RO.ts \
                src/qt/locale/xuez_ru.ts \
                src/qt/locale/xuez_sk.ts \
                src/qt/locale/xuez_sv.ts \
                src/qt/locale/xuez_tr.ts \
                src/qt/locale/xuez_uk.ts \
                src/qt/locale/xuez_zh_CN.ts \
                src/qt/locale/xuez_zh_TW.ts


contains(USE_QRCODE, 1) {
HEADERS += src/qt/qrcodedialog.h
SOURCES += src/qt/qrcodedialog.cpp
FORMS += src/qt/forms/qrcodedialog.ui
}

CODECFORTR = UTF-8

# for lrelease/lupdate
# also add new translations to src/qt/bitcoin.qrc under translations/
TRANSLATIONS = $$files(src/qt/locale/bitcoin_*.ts)

isEmpty(QMAKE_LRELEASE) {
    win32:QMAKE_LRELEASE = $$[QT_INSTALL_BINS]\\lrelease.exe
    else:QMAKE_LRELEASE = $$[QT_INSTALL_BINS]/lrelease
}
isEmpty(QM_DIR):QM_DIR = $$PWD/src/qt/locale
# automatically build translations, so they can be included in resource file
TSQM.name = lrelease ${QMAKE_FILE_IN}
TSQM.input = TRANSLATIONS
TSQM.output = $$QM_DIR/${QMAKE_FILE_BASE}.qm
TSQM.commands = $$QMAKE_LRELEASE ${QMAKE_FILE_IN} -qm ${QMAKE_FILE_OUT}
TSQM.CONFIG = no_link
QMAKE_EXTRA_COMPILERS += TSQM

# "Other files" to show in Qt Creator
OTHER_FILES += \
    doc/*.rst doc/*.txt doc/README README.md res/bitcoin-qt.rc

# platform specific defaults, if not overridden on command line
isEmpty(BOOST_LIB_SUFFIX) {
    macx:BOOST_LIB_SUFFIX = -mt
    windows:BOOST_LIB_SUFFIX=-mgw49-mt-s-1_57
}

isEmpty(BOOST_THREAD_LIB_SUFFIX) {
    BOOST_THREAD_LIB_SUFFIX = $$BOOST_LIB_SUFFIX
    #win32:BOOST_THREAD_LIB_SUFFIX = _win32$$BOOST_LIB_SUFFIX
    #else:BOOST_THREAD_LIB_SUFFIX = $$BOOST_LIB_SUFFIX
}

isEmpty(BDB_LIB_PATH) {
    macx:BDB_LIB_PATH = /usr/local/Cellar/berkeley-db4/4.8.30/lib
    windows:BDB_LIB_PATH=C:/dev/coindeps32/bdb-4.8/lib
}

isEmpty(BDB_LIB_SUFFIX) {
    macx:BDB_LIB_SUFFIX = -4.8
}

isEmpty(BDB_INCLUDE_PATH) {
    macx:BDB_INCLUDE_PATH = /usr/local/Cellar/berkeley-db4/4.8.30/include
    windows:BDB_INCLUDE_PATH=C:/dev/coindeps32/bdb-4.8/include
}

isEmpty(BOOST_LIB_PATH) {
    macx:BOOST_LIB_PATH = /usr/local/Cellar/boost/1.59.0/lib
    windows:BOOST_LIB_PATH=C:/dev/coindeps32/boost_1_57_0/lib
}

isEmpty(BOOST_INCLUDE_PATH) {
    macx:BOOST_INCLUDE_PATH = /usr/local/Cellar/boost/1.59.0/include
    windows:BOOST_INCLUDE_PATH=C:/dev/coindeps32/boost_1_57_0/include
}

isEmpty(QRENCODE_LIB_PATH) {
    macx:QRENCODE_LIB_PATH = /usr/local/lib
}

isEmpty(QRENCODE_INCLUDE_PATH) {
    macx:QRENCODE_INCLUDE_PATH = /usr/local/include
}

isEmpty(MINIUPNPC_LIB_SUFFIX) {
    windows:MINIUPNPC_LIB_SUFFIX=-miniupnpc
}

isEmpty(MINIUPNPC_INCLUDE_PATH) {
    macx:MINIUPNPC_INCLUDE_PATH=/usr/local/Cellar/miniupnpc/1.9.20151008/include
    windows:MINIUPNPC_INCLUDE_PATH=C:/dev/coindeps32/miniupnpc-1.9
}

isEmpty(MINIUPNPC_LIB_PATH) {
    macx:MINIUPNPC_LIB_PATH=/usr/local/Cellar/miniupnpc/1.9.20151008/lib
    windows:MINIUPNPC_LIB_PATH=C:/dev/coindeps32/miniupnpc-1.9
}

isEmpty(OPENSSL_INCLUDE_PATH) {
    macx:OPENSSL_INCLUDE_PATH = /usr/local/openssl-1.0.1p/include
    windows:OPENSSL_INCLUDE_PATH=C:/dev/coindeps32/openssl-1.0.1p/include
}

isEmpty(OPENSSL_LIB_PATH) {
    macx:OPENSSL_LIB_PATH = /usr/local/openssl-1.0.1p/lib
    windows:OPENSSL_LIB_PATH=C:/dev/coindeps32/openssl-1.0.1p/lib
}

# use: qmake "USE_UPNP=1" ( enabled by default; default)
#  or: qmake "USE_UPNP=0" (disabled by default)
#  or: qmake "USE_UPNP=-" (not supported)
# miniupnpc (http://miniupnp.free.fr/files/) must be installed for support
contains(USE_UPNP, -) {
    message(Building without UPNP support)
} else {
    message(Building with UPNP support)
    count(USE_UPNP, 0) {
        USE_UPNP=1
    }
    DEFINES += USE_UPNP=$$USE_UPNP MINIUPNP_STATICLIB STATICLIB
    INCLUDEPATH += $$MINIUPNPC_INCLUDE_PATH
    LIBS += $$join(MINIUPNPC_LIB_PATH,,-L,) -lminiupnpc
    win32:LIBS += -liphlpapi
}

windows:DEFINES += WIN32
windows:RC_FILE = src/qt/res/bitcoin-qt.rc

windows:!contains(MINGW_THREAD_BUGFIX, 0) {
    # At least qmake's win32-g++-cross profile is missing the -lmingwthrd
    # thread-safety flag. GCC has -mthreads to enable this, but it doesn't
    # work with static linking. -lmingwthrd must come BEFORE -lmingw, so
    # it is prepended to QMAKE_LIBS_QT_ENTRY.
    # It can be turned off with MINGW_THREAD_BUGFIX=0, just in case it causes
    # any problems on some untested qmake profile now or in the future.
    DEFINES += _MT BOOST_THREAD_PROVIDES_GENERIC_SHARED_MUTEX_ON_WIN
    QMAKE_LIBS_QT_ENTRY = -lmingwthrd $$QMAKE_LIBS_QT_ENTRY
}

macx:HEADERS += src/qt/macdockiconhandler.h src/qt/macnotificationhandler.h
macx:OBJECTIVE_SOURCES += src/qt/macdockiconhandler.mm src/qt/macnotificationhandler.mm
macx:LIBS += -framework Foundation -framework ApplicationServices -framework AppKit -framework CoreServices
macx:DEFINES += MAC_OSX MSG_NOSIGNAL=0
macx:ICON = src/qt/res/icons/xuez.icns
macx:TARGET = "XUEZ-Qt"
macx:QMAKE_CFLAGS_THREAD += -pthread
macx:QMAKE_LFLAGS_THREAD += -pthread
macx:QMAKE_CXXFLAGS_THREAD += -pthread
macx:QMAKE_INFO_PLIST = share/qt/Info.plist

# Set libraries and includes at end, to use platform-defined defaults if not overridden
INCLUDEPATH += $$BOOST_INCLUDE_PATH $$BDB_INCLUDE_PATH $$OPENSSL_INCLUDE_PATH $$QRENCODE_INCLUDE_PATH
LIBS += $$join(BOOST_LIB_PATH,,-L,) $$join(BDB_LIB_PATH,,-L,) $$join(OPENSSL_LIB_PATH,,-L,) $$join(QRENCODE_LIB_PATH,,-L,)
LIBS += -lssl -lcrypto -ldb_cxx$$BDB_LIB_SUFFIX
# -lgdi32 has to happen after -lcrypto (see  #681)
windows:LIBS += -lws2_32 -lshlwapi -lmswsock -lole32 -loleaut32 -luuid -lgdi32
!windows: {
    LIBS += -lgmp
} else {
    INCLUDEPATH += $$SECP256K1_INCLUDE_PATH
    LIBS += $$join(SECP256K1_LIB_PATH,,-L,) -lsecp256k1
}
LIBS += -lboost_system$$BOOST_LIB_SUFFIX -lboost_filesystem$$BOOST_LIB_SUFFIX -lboost_program_options$$BOOST_LIB_SUFFIX -lboost_thread$$BOOST_THREAD_LIB_SUFFIX
windows:LIBS += -lboost_chrono$$BOOST_LIB_SUFFIX

contains(RELEASE, 1) {
    !windows:!macx {
        # Linux: turn dynamic linking back on for c/c++ runtime libraries
        LIBS += -Wl,-Bdynamic
    }
}

!windows:!macx {
    DEFINES += LINUX
    LIBS += -lrt -ldl
}

system($$QMAKE_LRELEASE -silent $$_PRO_FILE_)