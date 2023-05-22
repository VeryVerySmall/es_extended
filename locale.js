var locale = [];

function _U() {
	var args = arguments;
	var string = args[0];
	if (!string) {
		console.log('locale.js: no string was parsed');
		return 'locale.js: no string was parsed';
	}
	if (locale.length == 0) {
		console.log('locale.js: no locale has been set');
		return 'locale.js: no locale has been set';
	}
	if (!locale[string]) {
		console.log('locale.js: translation [{0}] does not exist'.format(string));
		return 'locale.js: translation [{0}] does not exist'.format(string);
	}
	if (args.length == 1) {
		return capitalize(locale[string]);
	} else {
		return formatString(args);
	}
}

function formatString(args) {
	var string = capitalize(locale[args[0]]);
	for (var i = 1; i < args.length; i++) {
		string = string.replace(/%s/, args[i]);
	}
	return string;
}

function capitalize(string) {
	return string[0].toUpperCase() + string.slice(1);
}

String.prototype.format = function () {
	var args = arguments;
	return this.replace(/{(\d+)}/g, function (match, number) {
		return typeof args[number] != 'undefined' ? args[number] : match;
	});
};