.PHONY: hugo serve

default: hugo

hugo:
	cd src && $@ -d ../

serve:
	cd src && hugo serve -w
