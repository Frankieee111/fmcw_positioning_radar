%% 清理
clear;
close all;

%% 运行参数设置
doShowLo=0;
tShowPsProject=0.2;
useGPU=1;

%% 加载/提取数据、参数
nTx=4;
nRx=12;
rxCoor=[linspace(-0.053*(nRx/2-0.5),0.053*(nRx/2-0.5),nRx)',zeros(nRx,2)];
txCoor=[zeros(nTx,2),linspace(-0.138-0.053*(nTx-1),-0.138,nTx)'];
fCen=3.2e9;
fBw=1e9;
fSDown=200e3;
fRamp=800;
lRampDown=fSDown/fRamp;
lFft=512;
dLambda=3e8/fCen;
dMa=10;
dMi=1;
dCa=0;

fPm=fBw*fRamp/3e8;%frequency per meter

tsRamp=single((0:lRampDown-1)/fSDown);

tarCoor=[2,4,0.5];%target coordinate

%% 计算目标点反射回波下变频的中频信号
% 计算目标到各天线间的距离
dsRT=zeros(nRx,nTx,'single');
for iTx=1:nTx
    for iRx=1:nRx
        dsRT(iRx,iTx)=pdist([tarCoor;rxCoor(iRx,:)])+pdist([tarCoor;txCoor(iTx,:)]);
    end
end

yLoReshape=zeros(lRampDown,nRx,nTx,'single');
for iTx=1:nTx
    for iRx=1:nRx
        yLoReshape(:,iRx,iTx)=cos(2*pi*fPm*dsRT(iRx,iTx)*tsRamp+2*pi*dsRT(iRx,iTx)/dLambda);
    end
end
if doShowLo
    figure('name','yLo');
    yLo=reshape(yLoReshape,lRampDown,nRx*nTx);
    imagesc(1:nRx*nTx,tsRamp*1e6,yLo);
    set(gca, 'XDir','normal', 'YDir','normal');
    title('yLo');
    xlabel('天线编号');
    ylabel('tsRamp(us)');
end

%% 由粗到细算法
dxC=1;
dyC=1;
dzC=1;
C2Ffac=3;
nC2F=3;
C2Fratio=0.5;

xMi=-3;
xMa=3;
yMi=1;
yMa=5;
zMi=-1.5;
zMa=1.5;

xsC=single(xMi:dxC:xMa);
ysC=single(yMi:dyC:yMa);
zsC=single(zMi:dzC:zMa);
preciFac=C2Ffac.^(nC2F-1);
xsB=single(xMi:dxC/preciFac:xMa);
ysB=single(yMi:dyC/preciFac:yMa);
zsB=single(zMi:dzC/preciFac:zMa);
[xssB,yssB,zssB]=meshgrid(xsB,ysB,zsB);
psBcoor=[xssB(:),yssB(:),zssB(:)];
psB=zeros(size(xssB),'single','gpuArray');

if tShowPsProject
    hPs=figure('name','ps的xy投影图');
else
    hPs=[];
end
[psF,xsF,ysF,zsF]=rfcaptureC2F(dxC,dyC,dzC,xsC,ysC,zsC,psBcoor,psB, ...
    nC2F,C2Fratio,C2Ffac,tShowPsProject,hPs, ...
    yLoReshape,rxCoor,txCoor,nRx,nTx,dCa,tsRamp,fBw,fRamp,dLambda,useGPU);
