
CFLAGS = -g -Wall -ansi -pedantic

parser: miniL.lex miniL.y
	bison -d -v --file-prefix=y miniL.y
	flex miniL.lex
	g++ $(CFLAGS) -std=c+11 lex.yy.c y.tab.c -lfl -o parser
	rm -f lex.yy.c *.output *.tab.c *.tab.h

test: parser
	cat ./tests/min/primes.min | ./parser > ./tests/mil/primes.mil
	cat ./tests/min/mytest.min | ./parser > ./tests/mil/mytest.mil
	cat ./tests/min/fibonacci.min | ./parser > ./tests/mil/fibonacci.mil
	cat ./tests/min/errors.min | ./parser > ./tests/mil/errors.mil
	cat ./tests/min/for.min | ./parser > ./tests/mil/for.mil

# miniL: miniL-lex.o miniL-parser.o $(OBJS)
# 	$(CC) $^ -o $@ -lfl

# %.o: %.cpp
# 	$(CC) $(CFLAGS) -c $< -o $@

# miniL-lex.cpp: miniL.lex miniL-parser.cpp
# 	flex -o $@ $< 

# miniL-parser.cpp: miniL.y
# 	bison -d -v -g -o $@ $<

clean:
	rm -f *.o miniL-lex.cpp miniL-parser.cpp miniL-parser.hpp stack.hh *.output *.dot miniL