// Minimal headless runner: loads a QML file, exits with the code given to Qt.exit().
// Unlike `qml6`, it prints load errors.
#include <QCoreApplication>
#include <QQmlApplicationEngine>
#include <QQmlComponent>
#include <QUrl>
#include <QDebug>

int main(int argc, char **argv)
{
    QCoreApplication app(argc, argv);
    const QStringList args = app.arguments();
    if (args.size() < 3) {
        qCritical() << "usage: qml_runner <import-path> <file.qml>";
        return 2;
    }
    QQmlApplicationEngine engine;
    engine.addImportPath(args.at(1));
    QObject::connect(&engine, &QQmlApplicationEngine::exit, &app, &QCoreApplication::exit);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app,
                     [] { QCoreApplication::exit(3); }, Qt::QueuedConnection);
    engine.load(QUrl::fromLocalFile(args.at(2)));
    return app.exec();
}
