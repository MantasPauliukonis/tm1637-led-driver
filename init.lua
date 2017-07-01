require("tm1637")

-- pin clk, dio
tm1637.setup(2,1)
-- refresh
tm1637.clear()

i=1234
l=0
function test()
	s = tostring(i)
	tm1637.write(s)
	tm1637.dots()
--	tm1637.light(l)
	l=l+1
	if l>7 then
		l=0
	end
	i=i+1
end

--tm1637.fix(3,'B')
--tm1637.off()

tmr.alarm(0,2000,1,test)
