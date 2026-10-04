'use strict';
'require view';
'require form';
'require fs';
'require uci';
'require ui';

const CONTROL_SCRIPT = '/etc/scripts/ledcontrol/ledcontrol.sh';
const DEFAULT_ON_HOUR = '7';
const DEFAULT_OFF_HOUR = '23';
const DEFAULT_AUTO_ENABLED = '1';
const AUTO_ENABLED_INPUT_ID = 'widget.cbid.ledcontrol.settings.auto_enabled';

let statusNotification = null;

function showStatus(message, style) {
        if (statusNotification?.parentNode)
                statusNotification.parentNode.removeChild(statusNotification);

        statusNotification = ui.addNotification(null, E('p', {}, [ message ]), style);
        statusNotification.setAttribute('data-ledcontrol-notification', '1');
}

function updateAutomaticModeCheckbox(enabled) {
        const checkbox = document.getElementById(AUTO_ENABLED_INPUT_ID);

        if (checkbox)
                checkbox.checked = enabled;
}

function runMode(mode) {
        return fs.exec(CONTROL_SCRIPT, [ mode ]).then(function(result) {
                if (result.code !== 0)
                        throw new Error(result.stderr || _('The command failed.'));
        });
}

function runManualMode(mode) {
        return runMode(mode)
                .then(function() {
                        updateAutomaticModeCheckbox(false);
                        showStatus(_('LED mode changed to %s. Automatic mode disabled.').format(mode), 'info');
                })
                .catch(function(error) {
                        showStatus(_('Unable to change LED mode: %s').format(error.message), 'danger');
                });
}

function changeAutomaticMode(enabled) {
        return runMode(enabled ? 'auto-on' : 'auto-off')
                .then(function() {
                        showStatus(enabled ? _('Automatic mode enabled.') : _('Automatic mode disabled.'), 'info');
                })
                .catch(function(error) {
                        updateAutomaticModeCheckbox(!enabled);
                        showStatus(_('Unable to change automatic mode: %s').format(error.message), 'danger');
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

                option = section.option(form.Flag, 'auto_enabled', _('Automatic mode'),
                        _('Apply the schedule every five minutes. Manual LED controls disable this mode.'));
                option.default = DEFAULT_AUTO_ENABLED;
                option.enabled = '1';
                option.disabled = '0';
                option.rmempty = false;
                option.onchange = function(_event, _sectionId, value) {
                        return changeAutomaticMode(value === '1');
                };

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
                option.onclick = function() { return runManualMode('on'); };

                option = section.option(form.Button, '_off', _('Turn off'));
                option.inputstyle = 'negative';
                option.onclick = function() { return runManualMode('off'); };

                option = section.option(form.Button, '_reset', _('Reset defaults'));
                option.inputstyle = 'reset';
                option.onclick = function() {
                        return runMode('reset')
                                .then(function() {
                                        updateAutomaticModeCheckbox(true);
                                        showStatus(_('Default settings restored. Automatic mode enabled.'), 'info');
                                })
                                .catch(function(error) {
                                        showStatus(_('Unable to restore default settings: %s').format(error.message), 'danger');
                                });
                };

                return map.render();
        }
});
