compile: 
	cp -f ./src/edb.app ./ebin/edb.app
	cd src && erl -make -smp -Wall

clean:
	@rm -rf ebin/*.beam