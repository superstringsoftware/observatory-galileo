try {
    Package.describe({
        summary: "Observatory: Galileo. Foundational classes for the Observatory suite (http://observatoryjs.com). Meteor-independent.",
        version: "0.9.5",
        git: "https://github.com/superstringsoftware/observatory-galileo.git"
    });

    Package.on_use(function (api) {
        api.versionsFrom("METEOR@0.9.0");

        var both = ['client', 'server'];
        api.use(['coffeescript', 'underscore'], both);

        api.add_files('src/MessageEmitter.coffee', both);
        api.add_files('src/GenericEmitter.coffee', both);
        api.add_files('src/Logger.coffee', both);
        api.add_files('src/ConsoleLogger.coffee', both);
        api.add_files(['src/Observatory.coffee', 'src/Toolbox.coffee'], both);
        api.export(['Observatory'], both);
    });
}
catch (err) {
    console.log("Error while trying to load a package: " + err.message);
}
