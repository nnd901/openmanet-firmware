'use strict';
'require view';
'require form';

return view.extend({
	render: function () {
		var m, s, o;

		m = new form.Map('openmanet_usb_otg', _('USB OTG LAN share'),
			_('Share this device LAN with a PC, Mac, Android phone, or (rarely) iPhone over USB Ethernet. ' +
			  'The gadget cannot reliably detect the host OS before bind — Auto presents RNDIS+ECM ' +
			  '(never RNDIS-only) and may narrow to ECM after bridge FDB shows which function works. ' +
			  'Supported on Raspberry Pi Zero 2W and Pi 4 USB-C.'));

		s = m.section(form.NamedSection, 'main', 'openmanet_usb_otg', _('Settings'));
		s.addremove = false;

		o = s.option(form.Flag, 'enabled', _('Enable USB OTG LAN share'),
			_('Present a USB Ethernet gadget and attach it using the LAN share mode below.'));
		o.default = '1';
		o.rmempty = false;

		o = s.option(form.ListValue, 'share_mode', _('LAN share mode'),
			_('Bridge puts the USB host on the same LAN as br-lan, so LuCI/WebUI is reachable at the usual OpenMANET LAN IP or hostname. ' +
			  'NAT uses a separate USB subnet and needs extra firewall/routing for WebUI and multicast.'));
		o.value('bridge', _('Bridge into LAN (recommended — WebUI works out of the box)'));
		o.value('nat', _('NAT to a private USB subnet (advanced)'));
		o.default = 'bridge';
		o.rmempty = false;

		o = s.option(form.ListValue, 'gadget_preset', _('USB gadget type'),
			_('Auto / class choices map to gadget presets (no true OS detection). ' +
			  'Auto = RNDIS+ECM + universal MACs + UDC rebind + FDB narrow to ECM when exclusive. ' +
			  'A fixed choice always overrides Auto. iPhone often needs NCM and USB Host Mode.'));
		o.value('auto', _('Auto — mixed hosts (RNDIS+ECM, then FDB→ECM) — recommended'));
		o.value('android', _('Android phone → CDC ECM'));
		o.value('windows', _('Windows PC → CDC NCM'));
		o.value('apple', _('Mac / iPhone → CDC NCM'));
		o.value('rndis-ecm', _('Advanced: RNDIS + ECM composite (no Auto/FDB)'));
		o.value('ecm', _('Advanced: CDC ECM only'));
		o.value('ncm', _('Advanced: CDC NCM only'));
		o.value('rndis', _('Advanced: RNDIS only (not for Android)'));
		o.default = 'auto';
		o.rmempty = false;

		o = s.option(form.Value, 'nat_ip', _('NAT USB IPv4 address'),
			_('Pi address on the USB interface when using NAT mode.'));
		o.datatype = 'ip4addr';
		o.default = '192.168.42.1';
		o.depends('share_mode', 'nat');

		o = s.option(form.Value, 'nat_netmask', _('NAT USB netmask'));
		o.datatype = 'netmask4';
		o.default = '255.255.255.0';
		o.depends('share_mode', 'nat');

		o = s.option(form.Value, 'nat_start', _('NAT DHCP start offset'));
		o.datatype = 'uinteger';
		o.default = '100';
		o.depends('share_mode', 'nat');

		o = s.option(form.Value, 'nat_limit', _('NAT DHCP limit'));
		o.datatype = 'uinteger';
		o.default = '50';
		o.depends('share_mode', 'nat');

		return m.render();
	}
});
