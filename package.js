try {
    Package.describe({
        summary: "Observatory: Galileo. Foundational classes for the Observatory suite (http://observatoryjs.com). Meteor-independent.",
  version: "0.9.0",
  git: "https://github.com/superstringsoftware/observatory-galileo.git"
    });

    Package.on_use(function (api) {
  api.versionsFrom("METEOR@0.9.0");

        console.log("loading observatory: galileo");
        api.use(['coffeescript', 'underscore'], ['client','server']);
        //api.use(['webapp'], ['server']);

        api.add_files(['src/Observatory.coffee','src/Toolbox.coffee'],['client','server']);
        api.export (['Observatory'], ['client','server']);
    });
}
catch (err) {
    console.log("Error while trying to load a package: " + err.message);
}
