% Modular and tunable biological feedback control using a de novo protein switch
% Ng et al. (2019)
%
% Created by Mariana Gomez-Schiavon

clear
% Co-factors (hormones):
p.E = 30;%7.5;
p.P = 1.57;%1;

DY_eps = 0.15;

% myP  = 'P';
% myPn = 'Pg [nM]';
% pp   = 10.^[-1:0.05:2];%10.^[log10(0.1953):0.01:log10(50)];%
myP  = 'gZ';
myPn = '\gamma_Z [min^{-1}]';
pp   = 10.^[-1:0.05:2];

%% Parameters
p.mG  = 0.006;      % [0.005,0.02] nM/min | Constitutive synthesis rate
p.gG  = 0.02;
p.mZ  = 11;
p.aZ  = 0.000001;	% [0,1]
p.nZ  = 2.2;
p.kZ  = 36;         % [0.01,100] nM | Michaelis-Menten constants
p.gZ  = 0.01;       % [0.0048,0.0114] 1/min | RFP-psd degradation rate in dark
p.mY  = 0.125*6;
    p.kYa = 0.01;
    p.kYd = 0;%p.kYa/1000;
p.aY  = 0.03;       % [0,1]
p.gY  = 0.05;       % [0.0301,0.0408] 1/min | RFP-degODC degradation rate
p.mKc = 2;
p.mKo = 0.0028*100;     % [0.005,0.02] nM/min | Constitutive synthesis rate
p.aK  = 0.00001;    % [0,1]
p.nK  = 2.6;
p.kK  = 12;         % [0.01,100] nM | Michaelis-Menten constants
p.gK  = 0.01;       % [0.01,0.24] 1/min | Dilution rate (first-order)
p.e0  = 0.0001;     % [0.05,140] 1/min | Dissociation (unbinding) rate
p.eP  = 0.0375;     % [0.0012,2000] 1/nM 1/min | Association (binding) rate
p.eM  = 0.05;       % [0.03,2] 1/nM 1/min | Active (mass-action) degradation

% Functions:
FmZ  = @(x,c,m,a,n,k) [m*(a + ((1-a)*(((x*c).^n)./(((x*c).^n)+(k^n)))))];
FmY  = @(x,c,m,a,n,k) [m*(a + ((1-a)*(((x.*c).^n)./(((x.*c).^n)+(k^n)))))];
FmKc = @(x,c,m,a,n,k) [m*(a + ((1-a)*(((x*c).^n)./(((x*c).^n)+(k^n)))))];
FmKo = @(x,c,m,a,n,k) [m];

%% Steady states:
SS = zeros(2,length(pp),6);
for OL = 0:1
    if(OL)
        p.mK = p.mKo;
        FmK  = FmKo;
    else
        p.mK = p.mKc;
        FmK  = FmKc;
    end
    for i = 1:length(pp)
        p.(myP) = p.(myP)*pp(i);
        SS(OL+1,i,:) = FN_SS_Hill(p.P,p,FmZ,FmK,FmY,1e-5);
        p.(myP) = p.(myP)/pp(i);
    end
end
clear i OL

%% Feedback saturation threshold
i1 = [1:(length(pp)-1)]; i2 = i1 + 1;
ss = SS(1,:,1)+SS(1,:,4);
pI = p.(myP)*pp;
DY = abs(ss(i2)-ss(i1))./ss(i1);
DP(1,:) = abs(pI(i2)-pI(i1))./pI(i1);
DY = [NaN,DY./DP];
clear i1 i2 DP ss

%% Figure | Steady states
fig = figure();
fig.Units = 'inches';
fig.PaperPosition = [3.5 1 4 6];
fig.Position = fig.PaperPosition;

% Color scale
CM = colormap('parula');
CM = CM(64:-1:1,:);
ss = log10(SS(1,:,4)./(SS(1,:,1)+SS(1,:,4)));
C  = ceil(64*(ss-min(ss))/(max(ss)-min(ss)));
C([C==0]) = 1;
    clear ss

pI = p.(myP)*pp;

sP(1).data = log10(SS(:,:,6));
sP(2).data = log10(SS(:,:,3)+SS(:,:,4));
sP(3).data = log10(SS(:,:,4));
sP(4).data = log10(SS(:,:,1)+SS(:,:,4));
sP(5).data = log10(SS(:,:,2));

sP(1).ax = 0.82-0.01;
sP(2).ax = 0.64-0.01;
sP(3).ax = 0.46-0.01;
sP(4).ax = 0.28-0.01;
sP(5).ax = 0.10-0.01;

sP(1).yl = 'log_{10}Y';
sP(2).yl = 'log_{10}(K+C)';
sP(3).yl = 'log_{10}C';
sP(4).yl = 'log_{10}(G+C)';
sP(5).yl = 'log_{10}Z';

for ii = 1:5
    axes('Position',[0.09 sP(ii).ax 0.88 0.175])
    hold on;
    % Closed loop
    ss = sP(ii).data(1,:);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    d = DY;
    d([d<=DY_eps]) = min(ss)-100;
    d([d>DY_eps])  = max(ss)+100;
    plot(pI,d,'Color',[0.8 0.8 0.8],'LineStyle','--',...
        'LineWidth',1,'Marker','none')
    clear d
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    plot(pI,ss,'LineWidth',2,'Marker','none','Color',[0 0 0])
    xlim([min(pI) max(pI)])
    ylim([min(ss)-((max(ss)-min(ss))*0.1) max(ss)+((max(ss)-min(ss))*0.1)])
    % Open loop
    ss = sP(ii).data(2,:);
    plot(pI,ss,'LineWidth',2,'LineStyle','--','Color',[0 0 0])
        
        set(gca,'XScale','log','YScale','linear',...
            'YTickLabel','','XTickLabel','')
        box('on')
        clear i ss
        ylabel(sP(ii).yl)
end
    xlabel(myPn)
    set(gca,'XTick',10.^[-3:2],'XTickLabel',{'10^{-3}','10^{-2}','10^{-1}','10^{0}','10^{1}','10^{2}'})

%% END
