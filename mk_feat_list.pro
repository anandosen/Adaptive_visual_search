pro mk_feat_list, parfil, nfils,dim
  ;nfils=450
  filarr=strarr(nfils)
  
  ; Reading the list of image files
  openr,1,parfil
  readf,1,filarr
  free_lun,1
  
  ; Creating the Sobel filter versions of gradient and Laplacian
  dimx=dim
  dimy=dim
  hd=dim/2
  hdx=dimx/2
  hdy=dimy/2
  x0=hdx
  y0=hdy
  
  dx= fltarr(dimx,dimy)
  dx[*,*]= 0.0 & dy= dx 
  lap=dx
  
  dx[hdx-1,hdy-1]= -1 & dx[hdx+1,hdy-1]= 1
  dx[hdx-1,hdy]= -2 & dx[hdx+1,hdy]= 2
  dx[hdx-1,hdy+1]= -1 & dx[hdx+1,hdy+1]= 1
  dx= SHIFT(dx,-x0,-y0)
  
  dy[hdx-1,hdy-1]= -1 & dy[hdx-1,hdy+1]= 1
  dy[hdx,hdy-1]= -2 & dy[hdx,hdy+1]= 2
  dy[hdx+1,hdy-1]= -1 & dy[hdx+1,hdy+1]= 1
  dy= SHIFT(dy,-x0,-y0)
  
  fdx= FFT(dx,/DOUBLE,-1)
  fdy= FFT(dy,/DOUBLE,-1)
  
  lap[hdx-1,hdy-1]= 1 & lap[hdx,hdy-1]= 2 & lap[hdx+1,hdy-1]= 1
  lap[hdx-1,hdy]= 2 & lap[hdx,hdy]= -4 & lap[hdx+1,hdy]= 2
  lap[hdx-1,hdy+1]= 1 & lap[hdx,hdy+1]= 2 & lap[hdx+1,hdy+1]= 1
  lap= SHIFT(lap,-x0,-y0)
  flap= FFT(lap,/DOUBLE,-1)
  
  
  ; Reading the template file
  tgt= fltarr(dim,dim)
  close, 1
  openr, 1, 'targ_file'
  readu, 1, tgt
  close, 1
  tgt= tgt*(tgt gt 10E-6*max(tgt))
  ;tgtt= tgt[*,dim/2-hdy:dim/2+hdy-1]
  
  ftgt= FFT(tgt,/DOUBLE,-1)
  dim2=dimx*dimy
  
  ; Creating the feature-images from the template file
  
  tgtdx= dim2*float(FFT(ftgt*conj(fdx),/DOUBLE,/INVERSE))
  tgtdy= dim2*float(FFT(ftgt*conj(fdy),/DOUBLE,/INVERSE))
  tgtlap= dim2*float(FFT(ftgt*conj(flap),/DOUBLE,/INVERSE))
  
  ; Creating the channelized feature image
  nchan=3
  if (nchan gt 0) then BEGIN
      tgtch= fltarr(dim,dim) & tgtch[*,*]= 0
      chan= fltarr(2*dim,2*dim,nchan)
      openr, 1, 'psfs128'
      readu, 1, chan
      close, 1
      chan= chan[hd:(hd+dim-1),hd:(hd+dim-1),*]
      stgt= fltarr(nchan)
      for j=0,(nchan-1) do BEGIN
        stgt[j]= TOTAL(chan[*,*,j]*tgt)
      ENDFOR
      ;print, k, invert(k), stgt
      ;stgt= INVERT(k) # stgt & print, stgt
      for i=0,(nchan-1) do BEGIN
        ;tvscl, chan[*,*,i]*TOTAL(chan[*,*,i]*tgt), i
        tgtch= tgtch+chan[*,*,i]*stgt[i]
        ;tvscl, tmpl, 3+i
      ENDFOR
    ENDIF
  
   mask=fltarr(dim,dim,dim)
   openr, 1, 'attfil'
   readu, 1, mask
   close, 1
      
  img = fltarr(dim,dim)
  featimg1=fltarr(dim,dim)
  featimg2=featimg1
  featimg3=featimg1
  featimg4=featimg1
  
  nocand=0
  openw,6,'feat_file'
  
  ; Creating the feature table for each image file. Stored in feature_file (raw) and norm_feat_file (normalized)
  for i=0,nfils-1 do begin
    img = bytarr(dim,dim)
    openr, 1, filarr[i]
    readu, 1, img
    close, 1
    img=1.0*img
    
    POSZ= (fix(STRMID(filarr[i], 2, 3, /reverse_offset)))
    
    POSX= (fix(STRMID(filarr[i], 8, 3, /reverse_offset)))
    POSY= (fix(STRMID(filarr[i], 5, 3, /reverse_offset)))
    ;status=(fix(STRMID(filarr[i], 48, 1, /reverse_offset)))
    POSY=127-posy
    fileno=fix((strsplit(filarr[i],'_',/extract))[19])
    status=fix((strsplit(filarr[i],'_',/extract))[7])
    searchmask=mask(*,*,POSZ)
    
    fimg= FFT(img,/DOUBLE,-1)
    imgdx= dim2*float(FFT(fimg*conj(fdx),/DOUBLE,/INVERSE))
    imgdy= dim2*float(FFT(fimg*conj(fdy),/DOUBLE,/INVERSE))
    imglap= dim2*float(FFT(fimg*conj(flap),/DOUBLE,/INVERSE))
    
    featimg1=convolve(img,tgt,dimx,dimy,/mat,/noout,/corr)
    featimg2=convolve(imgdx,tgtdx,dimx,dimy,/mat,/noout,/corr)+convolve(imgdy,tgtdy,dimx,dimy,/mat,/noout,/corr)
    featimg3=convolve(imglap,tgtlap,dimx,dimy,/mat,/noout,/corr)
    featimg4=convolve(img,tgtch,dimx,dimy,/mat,/noout,/corr)
    
    searchfeat=featimg2
    
    clusterpts=fltarr(dim,dim)
    tmpmap=clusterpts
    ; Wateshed Clustering
    clusterpts2= -WATERSHED(bytscl(-searchfeat),CONNECTIVITY=8, /LONG, NREGIONS=nws)
    ;print, 'WS blobs= ', nws
    for l=1,nws do BEGIN
      cind= WHERE(clusterpts2 eq -l)
      ;print, l, n_elements(cind)
      t= max(searchfeat[cind],tind)
      ;for lower threshold
      ;if ((searchmask[cind[tind]] gt 0) and ((prt[cind[tind]]-mvalue)/stndev gt threshold)) then 
      tmpmap[cind[tind]]= 1
    ENDFOR
    
    tmpmap=searchmask*tmpmap
    maxpts= WHERE(tmpmap eq 1,nmax)
    
    if (nmax lt 1) then begin
      stat= searchmask*searchfeat
      maxpts=where(stat eq max(stat),nmax)
      ;maxpts=1
      ;nmax=1
    endif
    
    for l=0,nmax-1 do begin
      pos=maxpts[l]
      x=pos mod dimx
      y=pos/dimy
      r=sqrt((x-POSX)^2+(y-POSY)^2)
      locstat=(r le 5) && (status eq 1)
      humanstat= ' 0 ' 
      printf,6, locstat, humanstat, searchfeat[pos], featimg1[pos], featimg2[pos], featimg3[pos], featimg4[pos], fileno
      nocand=nocand+1
    endfor
  endfor
  free_lun,6
  
  ;normalizing
  feat_data=fltarr(8,nocand)
  openr,1,'feat_file'
  readf,1,feat_data
  free_lun,1
  
  totalmean=fltarr(4)
  totalstd=fltarr(4)
  for j=3,6 do begin
    totalmean[j-3]=mean(feat_data[j,*])
    totalstd[j-3]=stddev(feat_data[j,*])
    feat_data[j,*]=(feat_data[j,*]-mean(feat_data[j,*]))/stddev(feat_data[j,*])
  endfor
  
  locstat=feat_data[0,*]
  deltatmp=fltarr(4)
  
  
  for j=3,6 do BEGIN
   feat=feat_data[j,*]
   lpmean=mean(feat(where(locstat eq 1)))
   lamean=mean(feat(where(locstat eq 0)))
   deltatmp[j-3]=lpmean-lamean
  endfor
  
  openw,6,'norm_feat_file'
  for i=0,nocand-1 do begin
    locstat=strtrim(string(fix(feat_data[0,i])),2)
    humanstat=' '+strtrim(string(fix(feat_data[1,i])),2)
    fileno=' '+strtrim(string(fix(feat_data[7,i])),2)
    printf,6, locstat, humanstat, feat_data[2,i], feat_data[3,i], feat_data[4,i], feat_data[5,i], feat_data[6,i], fileno
  endfor
  free_lun,6
  
  ; Storing summarizing statistics delta, mean and standard deviation
  openw,6,'delta'
  printf,6,deltatmp
  printf,6,totalmean
  printf,6,totalstd
  free_lun,6
end