'use strict';
'require view';
'require form';
'require fs';
'require uci';
'require ui';

const CONTROL_SCRIPT = '/etc/scripts/ledcontrol/ledcontrol.sh';
const DEFAULT_ON_HOUR = '7';
const DEFAULT_OFF_HOUR = '23';

function runMode(mode) {
        return fs.exec(CONTROL_SCRIPT, [ mode ]).then(function(result) {
                if (result.code !== 0)
                        throw new Error(result.stderr || _('The command failed.'));

                ui.addNotification(null, E('p', {}, [
                        _('LED mode changed to %s.').format(mode)
                ]), 'info');
        }).catch(function(error) {
                ui.addNotification(null, E('p', {}, [
                        _('Unable to change LED mode: %s').format(error.message)
                ]), 'danger');
        });
}

function addHourOptions(option) {
        for (let hour = 0; hour < 24; hour++) {
                const value = String(hour);
                const label = String(hour).padStart(2, '0') + ':00';
                option.value(value, label);
        }
}

return view.extend({
        load() {
                return uci.load('ledcontrol');
        },

        render() {
                let option;
                const map = new form.Map('ledcontrol', _('LED Control'),
                        _('Set the daily interval when the router LEDs are on. The selected mode is checked every five minutes.'));
                const section = map.section(form.NamedSection, 'settings', 'ledcontrol', _('Schedule'));

                section.anonymous = true;

                option = section.option(form.ListValue, 'on_hour', _('Turn on at'));
                option.rmempty = false;
                option.default = DEFAULT_ON_HOUR;
                addHourOptions(option);

                option = section.option(form.ListValue, 'off_hour', _('Turn off at'));
                option.rmempty = false;
                option.default = DEFAULT_OFF_HOUR;
                addHourOptions(option);

                option = section.option(form.Button, '_on', _('Turn on'));
                option.inputstyle = 'positive';
                option.onclick = function() { return runMode('on'); };

                option = section.option(form.Button, '_off', _('Turn off'));
                option.inputstyle = 'negative';
                option.onclick = function() { return runMode('off'); };

                option = section.option(form.Button, '_auto', _('Automatic mode'));
                option.inputstyle = 'primary';
                option.onclick = function() { return runMode('auto'); };

                option = section.option(form.Button, '_reset', _('Reset defaults'));
                option.inputstyle = 'reset';
                option.onclick = function() {
                        uci.set('ledcontrol', 'settings', 'on_hour', DEFAULT_ON_HOUR);
                        uci.set('ledcontrol', 'settings', 'off_hour', DEFAULT_OFF_HOUR);

                        return uci.save()
                                .then(function() { return uci.apply(); })
                                .then(function() { return runMode('auto'); });
                };

                return map.render();
        }
});
