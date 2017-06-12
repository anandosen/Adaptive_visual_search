pro avg_lroc, indiv

openr,1,indiv

s=strarr(106)
tempstr=strarr(1)
i=0
while ~ eof(1) do begin
   readf, 1, tempstr
   s[i]=tempstr
   i=i+1
endwhile
free_lun,1
s=s[2:i:7]
siz=(size(s))[1]
t=fltarr(siz)
i=0
while (i lt siz) do begin
  t[i]=float((strsplit(s[i],'=',/extract))[1])
  i=i+1
endwhile
openw,1,'lroc_temp'
printf,1,mean(t)
free_lun,1
;print,mean(t)
end
