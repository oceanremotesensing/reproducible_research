function Syn_ratio(dsnrs)
% Author      : Yangkang Chen
% Date        : Dec, 2020
% 
% Requirements: RSF (http://rsf.sourceforge.net/) with Matlab API
%    
%  Copyright (C) 2020 The University of Texas at Austin
%  Copyright (C) 2020 Yangkang Chen
%  
%  This program is free software; you can redistribute it and/or modify
%  it under the terms of the GNU General Public License as published by
%  the Free Software Foundation; either version 2 of the License, or
%  (at your option) any later version.
%  
%  This program is distributed in the hope that it will be useful,
%  but WITHOUT ANY WARRANTY; without even the implied warranty of
%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%  GNU General Public License for more details.
%  
%  You should have received a copy of the GNU General Public License
%  along with this program; if not, write to the Free Software
%  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  
% 
%  Reference:   Chen et al., NC, 2019

%% load data

fid=fopen('syn_us_d_200_100_100.bin','r');
d=fread(fid,[200,100*100],'float');
d=reshape(d,200,100,100);

fid=fopen('syn_us_dn_200_100_100.bin','r');
dn=fread(fid,[200,100*100],'float');
dn=reshape(dn,200,100,100);

randn('state',201314);
var=0.1;

ratios=[0.1:0.1:0.9];
nr=length(ratios);
snrs0=zeros(nr,1);
snrs1=zeros(nr,1);
snrs2=zeros(nr,1);

for ir=1:nr;
ratio=ratios(ir);
mask=yc_genmask(reshape(d,nt,nx*ny),ratio,'c',2014151617);
mask=reshape(mask,nt,nx,ny);

% randn('state',201314);
% dn=d+var*randn(size(d));
d0=dn.*mask;

%% local processing
% 
Niter=10;
param.dt=0.004;
param.flow=0;
param.fhigh=100;
param.N=3;
% param.NN=3;
param.niter=Niter;
param.a=(Niter-(1:Niter))/(Niter-1); %linearly decreasing;
param.eps=0.00001;
param.mode=1;
param.verb=1;

n1win=50;n2win=50;n3win=50;
% twin=n1;xwin=n2;
r1=0.5;r2=0.5;r3=0.5;
%% Main program goes here !
D1_win=win3d_mask(@localfxymssa_recon, mask, param, d0, n1win, n2win, n3win, r1, r2, r3);
% D1_win=win3d_mask(@localfxydmssa_recon, mask, param, dn, n1win, n2win, n3win, r1, r2, r3);
figure;imagesc([d(:,:,9),d0(:,:,9),D1_win(:,:,9),d(:,:,9)-D1_win(:,:,9)]);
yc_snr(d,D1_win,2)

snrs0(ir)=yc_snr(d(40:100,:,:),d0(40:100,:,:),2);
snrs1(ir)=yc_snr(d(40:100,:,:),D1_win(40:100,:,:),2);

% 
%% global processing
flow=0;fhigh=12.5;dt=0.04;N=30;Niter=10;mode=1;verb=0;
N=10;
a=(Niter-(1:Niter))/(Niter-1); %linearly decreasing
D1=fxymssa_recon(d0,mask,flow,fhigh,dt,N,Niter,eps,verb,mode,a);
figure;imagesc([d(:,:,9),d0(:,:,9),D1(:,:,9),d(:,:,9)-D1(:,:,9)]);
yc_snr(d,D1,2)

snrs2(ir)=yc_snr(d(40:100,:,:),D1(40:100,:,:),2);

fprintf('Ratio=%g is done, snr0=%g,snr1=%g,snr2=%g\n',ratios(ir),snrs0(ir),snrs1(ir),snrs2(ir));

% 
% NN=3;
% D2=fxydmssa_recon(d0,mask,flow,fhigh,dt,N,NN,Niter,eps,verb,mode,a);
% figure;imagesc([d(:,:,9),d0(:,:,9),D2(:,:,9),d(:,:,9)-D2(:,:,9)]);
% yc_snr(d,dn,2)
% yc_snr(d,d0,2)
% yc_snr(d,D2,2)
% figure;imagesc([d(:,:,5),d0(:,:,5),D2(:,:,5),d(:,:,5)-D2(:,:,5)]);
% 
% %% linear interpolation
% [lon2,lat2]=meshgrid(lon,lat);
% 
% rf2d=reshape(d0,nt,nx*ny);
% mask2d=reshape(mask,nt,nx*ny);
% indexmask=find(mask2d(1,:)~=0);
% rf2d=rf2d(:,indexmask);
% lon1_2d=reshape(lon2,1,nx*ny);
% lat1_2d=reshape(lat2,1,nx*ny);
% lon1=lon1_2d(indexmask);
% lat1=lat1_2d(indexmask);
% 
% d1=2.8;
% d2=5.6;
% 
% irf2d_yk=zeros(nt,nx*ny);
% nx0=size(rf2d,2);
% %% inter by YKC using the same method
% for ix=1:nx*ny
%    r=sqrt(sum(([lat1-lat2(ix);lon1-lon2(ix)]).^2,1));
% %    [max(r),min(r)]
%    
%    index1=find(r<=d1); 
%    index2=find(r>d1 & r<d2);
%    
%    nw1=length(index1);
%    nw2=length(index2);
% 
%    w=zeros(1,nx0);
%    
%    w(index1)=ones(1,nw1);
%    w(index2)=(r(index2)-d1)/(d1-d2)+1;
%    
%    irf2d_yk(:,ix)=sum((ones(nt,1)*w).*rf2d,2)/sum(w);
% end
% irf2d_yk3d=reshape(irf2d_yk,nt,nx,ny);
% 
% figure;imagesc([d(:,:,9),d0(:,:,9),irf2d_yk3d(:,:,9),d(:,:,9)-irf2d_yk3d(:,:,9)]);
% 
% figure;imagesc([d(:,:,20),d0(:,:,20),irf2d_yk3d(:,:,20),d(:,:,20)-irf2d_yk3d(:,:,20)]);
% 
% yc_snr(d,irf2d_yk3d,2)
% 
% 
% 
% 
% 

end

%fid=fopen('syn_us_ratios_snrs.bin','w');
%fwrite(fid,[snrs0,snrs1,snrs2],'float');

%ratio=0.1: 4.7284;4.2651
%ratio=0.2: 9.8721;8.6852;
%ratio=0.3: 14.5532;11.7224
%ratio=0.4: 18.4519,15.1889
%ratio=0.5: 20.5601,17.4001
%ratio=0.6: 20.9589,17.7631
%ratio=0.7: 21.0329,17.9402

snrs=[snrs0,snrs1,snrs2];

%% from Matlab to Madagascar
rsf_create(dsnrs,size(snrs)');
rsf_write(snrs,dsnrs);








