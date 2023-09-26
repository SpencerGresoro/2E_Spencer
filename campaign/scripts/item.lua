-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	onStateChanged();
end

function onLockChanged()
	onStateChanged();
end
function onIDChanged()
	onStateChanged();
end

function onStateChanged()
	if header.subwindow then
		header.subwindow.update();
	end
	if main.subwindow then
		main.subwindow.update();
	end
end
