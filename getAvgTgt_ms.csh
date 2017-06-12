#!/bin/csh -f
if ( $#argv == 0 ) then
  echo "Must enter .par filename"
  exit
endif
set parfil = $1
set DIM = $2
set DAT = $3
set cdir = ${PWD}

# Get only abnormal noisy images
awk '{print ($1);}' ${parfil} | grep -v '_lesion_0' | grep -v 'counts_nan' >! tmpfils
awk '{print ($1);}' ${parfil} | grep '_lesion_0' | grep -v 'counts_nan' >! tmpfilsNo

set locpts = `sed "s/[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]/ & /g" tmpfils | awk '{print $2};' | tee ${cdir}/tmplocs`
cd ${cdir}
set nfils = $#locpts

# Create idl script for computing mean lesion
echo "close, 1, 2, 3\
dim= ${DIM}\
dtyp= '${DAT}'\
nfils= $nfils" >! getAvgTgt.pro
echo 'filnam= strarr(nfils)\
if ( dtyp eq "b" ) then BEGIN & $\
img= bytarr(dim,dim) & $\
imgNo= bytarr(dim,dim) & $\
ENDIF else if ( dtyp eq "f" ) then BEGIN & $\
img= fltarr(dim,dim) & $\
imgNo= fltarr(dim,dim) & $\
ENDIF\
mimg= fltarr(dim,dim)\
mimg[*,*]= 0.0\
mimg2= mimg\
posid= ""\
filstr= ""\
openr, 1, "tmpfils"\
openr, 2, "tmpfilsNo"\
openr, 3, "tmplocs"\
for i=0,(nfils-1) do BEGIN & $\
;\
  readf, 1, filstr & $\
  openr, 4, filstr & $\
  readu, 4, img & $\
  close, 4 & $\
  ;img= rotate(img,7) & $\
  ;print, filstr & $\
;\
  readf, 2, filstr & $\
  openr, 4, filstr & $\
  readu, 4, imgNo & $\
  close, 4 & $\
  ;print, filstr & $\
;\
  readf, 3, posid & $\
  ;POSX= (dim/128)*(fix(STRMID(posid, 0, 3))) & $\
  ;POSY= (dim/128)*(fix(STRMID(posid, 3, 3))) & $\
  POSX= (fix(STRMID(posid, 0, 3))) & $\
  POSY= (fix(STRMID(posid, 3, 3))) & $\
  POSZ= (fix(STRMID(posid, 6, 3))) & $\
  SHX= (dim/2)-POSX & $\
  SHY= (dim/2)-POSY & $\
  ;tgt= (rotate(1.0*img,7)-rotate(1.0*imgNo,7)) & $\
  tgt= (rotate(1.0*img-1.0*imgNo,7)) & $\
  ;tgt= (1.0*img)-(1.0*imgNo) & $\
  tgt= SHIFT(tgt,SHX,SHY) & $\
  openw, 4, "_tgtem.tmp" & $\
  writeu, 4, tgt & $\
  close, 4 & $\
  ;;gmm_spectfit_oneblob, infil="_tgtem.tmp", idim=256, kdim=1, rdim=1, nitr=5 & $\
  ;tvscl, tgt, 0 & $\
  ;tvscl, img, 1 & $\
  ;tvscl, imgNo, 2 & $\
  mimg= mimg+tgt & $\
  ;tvscl, mimg, 3 & $\
  ;wait, 5 & $\
ENDFOR\
mimg= mimg/nfils\
close, 1, 2, 3\
h= dim/2 & g= 15\
mimg2[h-g:h+g,h-g:h+g]= mimg[h-g:h+g,h-g:h+g]\
;;;mimg= mimg2\
;mimg= mimg*(mimg gt 0.0)\
;mimg= mimg/total(mimg)\
openw, 1, "targ_file"\
writeu, 1, mimg\
close, 1' >> getAvgTgt.pro
idl < getAvgTgt.pro

rm -f getAvgTgt.pro tmpfils tmpfilsNo tmplocs
