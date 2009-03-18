SOURCE = mon

PRE = part

AS = zmac


all: mon.s 64180.h 
	/lib/cpp -P $(SOURCE).s > $(PRE).z
	$(AS)  -h $(PRE)

	mv $(PRE).lst $(SOURCE).lst
	mv $(PRE).hex $(SOURCE).hex
	rm $(PRE).z

print:
	
