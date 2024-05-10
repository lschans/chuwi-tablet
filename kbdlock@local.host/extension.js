import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as PanelMenu from 'resource:///org/gnome/shell/ui/panelMenu.js';
import * as PopupMenu from 'resource:///org/gnome/shell/ui/popupMenu.js';
import * as QuickSettings from 'resource:///org/gnome/shell/ui/quickSettings.js';
import * as MessageTray from 'resource:///org/gnome/shell/ui/messageTray.js';

import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import GObject from 'gi://GObject';

const KBDLockIndicator = GObject.registerClass(
class KBDLockIndicator extends QuickSettings.SystemIndicator {
    _init(extensionObject) {
        super._init();

        // Create an icon for the indicator
        this._indicator = this._addIndicator();
        this._indicator.icon_name = 'input-tablet-symbolic';
	this._indicator.visible = false;
    }
});

const KBDLockToggle = GObject.registerClass(
class KBDLockToggle extends QuickSettings.QuickToggle {
    _init(extensionObject) {
        super._init({
            title: _('KBD Locked'),
            iconName: 'input-tablet-symbolic',
            toggleMode: true,
        });
	    
     this.connectObject('clicked', () => this._toggleKBD(), this);
    }

    _toggleKBD() {
	let [success, stdout, stderr] = GLib.spawn_command_line_sync("/usr/bin/bash /opt/kbdlock/" + (this.checked ? "enable" : "disable") + ".sh")
            if (!success) {
                Main.notify('KBD Lock', 'Error changing keyboard state' );
                return []
            }
    }
});

export default class KBDLockExtension extends Extension {
    enable() {
        this._indicator = new KBDLockIndicator(this);
        this._indicator.quickSettingsItems.push(new KBDLockToggle(this));		
        Main.panel.statusArea.quickSettings.addExternalIndicator(this._indicator);
    }

    disable() {
        this._indicator.quickSettingsItems.forEach(item => item.destroy());
        this._indicator.destroy();
        this._indicator = null;
    }
}


