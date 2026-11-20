#include <QtTest>
#include <QSignalSpy>
#include <QTemporaryDir>
#include <QFile>
#include <QDir>

#include "../iohelper.h"

class TstIoHelper : public QObject
{
    Q_OBJECT
private Q_SLOTS:
    void readMissingFile_returnsEmptyAndExistsFalse()
    {
        IoHelper io;
        QVERIFY(!io.exists(QStringLiteral("/nonexistent/file.json")));
        QCOMPARE(io.readFile(QStringLiteral("/nonexistent/file.json")), QString());
    }

    void writeThenRead_roundTrips_andCreatesParentDirs()
    {
        QTemporaryDir dir;
        IoHelper io;
        const QString path = dir.filePath(QStringLiteral("a/b/rules.json"));
        QVERIFY(io.writeFile(path, QStringLiteral("{\"é\":1}")));
        QVERIFY(io.exists(path));
        QCOMPARE(io.readFile(path), QStringLiteral("{\"é\":1}"));
    }

    void write_replacesAtomically_noTempLeftovers()
    {
        QTemporaryDir dir;
        IoHelper io;
        const QString path = dir.filePath(QStringLiteral("rules.json"));
        QVERIFY(io.writeFile(path, QStringLiteral("one")));
        QVERIFY(io.writeFile(path, QStringLiteral("two")));
        QCOMPARE(io.readFile(path), QStringLiteral("two"));
        QCOMPARE(QDir(dir.path()).entryList(QDir::Files).size(), 1);
    }

    void write_toUnwritableLocation_returnsFalse()
    {
        IoHelper io;
        QVERIFY(!io.writeFile(QStringLiteral("/proc/nope/rules.json"), QStringLiteral("x")));
    }

    void expandsLeadingTilde()
    {
        IoHelper io;
        QCOMPARE(io.expandPath(QStringLiteral("~/x")), QDir::homePath() + QStringLiteral("/x"));
        QCOMPARE(io.expandPath(QStringLiteral("/abs")), QStringLiteral("/abs"));
    }

    void exePath_resolvesOwnPid_andReturnsEmptyForBadPid()
    {
        IoHelper io;
        const QString exe = io.exePath(QCoreApplication::applicationPid());
        QCOMPARE(exe, QFileInfo(QCoreApplication::applicationFilePath()).canonicalFilePath());
        QCOMPARE(io.exePath(0), QString());
        QCOMPARE(io.exePath(-5), QString());
        QCOMPARE(io.exePath(999999999), QString());
    }

    void exePath_isCachedPerPid()
    {
        IoHelper io;
        const qint64 pid = QCoreApplication::applicationPid();
        io.exePath(pid);
        QCOMPARE(io.exeCacheSize(), 1);
        io.exePath(pid);
        QCOMPARE(io.exeCacheSize(), 1);
    }

    void watch_emitsOnPlainWrite()
    {
        QTemporaryDir dir;
        const QString path = dir.filePath(QStringLiteral("rules.json"));
        QFile f(path); QVERIFY(f.open(QIODevice::WriteOnly)); f.write("a"); f.close();
        IoHelper io;
        QSignalSpy spy(&io, &IoHelper::fileChanged);
        io.watch(path);
        QVERIFY(f.open(QIODevice::WriteOnly | QIODevice::Append)); f.write("b"); f.close();
        QVERIFY(spy.wait(2000));
        QCOMPARE(spy.first().first().toString(), path);
    }

    void watch_survivesAtomicSaves_repeatedly()
    {
        QTemporaryDir dir;
        const QString path = dir.filePath(QStringLiteral("rules.json"));
        IoHelper writer;
        QVERIFY(writer.writeFile(path, QStringLiteral("0")));
        IoHelper io;
        QSignalSpy spy(&io, &IoHelper::fileChanged);
        io.watch(path);
        for (int i = 1; i <= 3; ++i) {
            // editor-style: write temp file, rename over target
            const QString tmp = path + QStringLiteral(".tmp");
            QFile t(tmp); QVERIFY(t.open(QIODevice::WriteOnly)); t.write(QByteArray::number(i)); t.close();
            QFile::remove(path);
            QVERIFY(QFile::rename(tmp, path));
            QVERIFY2(spy.wait(2000), qPrintable(QStringLiteral("no signal for save %1").arg(i)));
            spy.clear();
        }
    }

    void watch_picksUpFileCreatedLater()
    {
        QTemporaryDir dir;
        const QString path = dir.filePath(QStringLiteral("rules.json"));
        IoHelper io;
        QSignalSpy spy(&io, &IoHelper::fileChanged);
        io.watch(path);
        IoHelper writer;
        QVERIFY(writer.writeFile(path, QStringLiteral("x")));
        QVERIFY(spy.wait(2000));
    }
};

QTEST_MAIN(TstIoHelper)
#include "tst_iohelper.moc"
