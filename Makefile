.PHONY: clean hugo serve

default: hugo

clean:
	rm -rv docs/* || true

hugo:
	$@ -d docs

serve:
	hugo serve -w
