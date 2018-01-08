
all: parse lex compile

parse:
	bison -d parser.y

lex:
	flex lexer.l

compile:
	g++ -std=c++0x -o synth -g lex.yy.c parser.tab.c main.c module.c -Wno-write-strings -Wno-deprecated -Wfatal-errors

run:
	./synth

clean:
	rm *.tab.c *.tab.h *.yy.c pdlsyn

