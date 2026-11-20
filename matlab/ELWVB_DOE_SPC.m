%% ELWVB_DOE_SPC.m
% Spatial DOE and SPC analysis for the Energy-Landscape Wafer Variation
% Benchmark (ELWVB).
%
% The script is written for MATLAB R2024b or later.
%
% IMPORTANT:
% ELWVB is a synthetic benchmark. The DOE below is a model-based/retrospective
% engineering analysis, not a claim that the benchmark observations came from
% controlled fab experiments.

clear; close all; clc;

%% 0. Configuration
dataFile = fullfile("..","data","wafer_site_data.csv");
outDir   = fullfile("..","outputs_matlab");
if ~exist(outDir,"dir"); mkdir(outDir); end

if ~isfile(dataFile)
    error("wafer_site_data.csv was not found in the data folder.");
end

T = readtable(dataFile);
disp("Dataset loaded:");
disp(size(T));

required = ["x","y","r","cd","thickness","hotspot_mask","p_defect","failure"];
missing = required(~ismember(required, string(T.Properties.VariableNames)));
if ~isempty(missing)
    error("Missing required variables: %s", strjoin(missing,", "));
end

%% 1. Data cleaning
vars = ["x","y","r","cd","thickness","hotspot_mask","p_defect","failure"];
T = rmmissing(T, "DataVariables", cellstr(vars));

% Ensure binary response is numeric.
if ~isnumeric(T.failure)
    T.failure = double(categorical(T.failure));
end

T.failure = double(T.failure > 0);

fprintf("\nNumber of usable wafer sites: %d\n", height(T));
fprintf("Overall failure rate: %.4f (%.2f%%)\n", ...
    mean(T.failure), 100*mean(T.failure));

%% ========================================================================
% 2. DOE
% =========================================================================

% The dataset does not contain physical scanner settings such as exposure
% dose or focus. Therefore, CD and thickness are treated as process-response
% factors for an engineering DOE. A retrospective factorial analysis is first
% performed using low/medium/high quantile regions.
%
% This does NOT establish causal effects. It establishes statistical
% association across factor regions.

%% 2.1 Define factor levels
q = [1/3, 2/3];

cdQ = quantile(T.cd,[q]);
thQ = quantile(T.thickness,[q]);

T.CD_Level = discretize(T.cd, ...
    [-Inf cdQ(1) cdQ(2) Inf], ...
    "categorical",["Low","Medium","High"]);

T.Thickness_Level = discretize(T.thickness, ...
    [-Inf thQ(1) thQ(2) Inf], ...
    "categorical",["Low","Medium","High"]);

T.CD_Code = double(T.CD_Level);
T.Thickness_Code = double(T.Thickness_Level);

%% 2.2 Factorial cell summary
[G,cdLevel,thLevel] = findgroups(T.CD_Level,T.Thickness_Level);

DOE = table;
DOE.CD_Level = cdLevel;
DOE.Thickness_Level = thLevel;
DOE.n = splitapply(@numel,T.failure,G);
DOE.FailureRate = splitapply(@mean,T.failure,G);
DOE.MeanPDefect = splitapply(@mean,T.p_defect,G);
DOE.MeanCD = splitapply(@mean,T.cd,G);
DOE.MeanThickness = splitapply(@mean,T.thickness,G);

writetable(DOE,fullfile(outDir,"DOE_factorial_summary.csv"));

disp("Retrospective 3x3 DOE summary:");
disp(DOE);

%% 2.3 Main-effects plots
figure("Color","w");
tiledlayout(1,2);

nexttile;
cdEffect = groupsummary(T,"CD_Level","mean",["failure","p_defect"]);
plot(1:3,cdEffect.mean_failure,"-o","LineWidth",1.5);
xticks(1:3); xticklabels(["Low","Medium","High"]);
xlabel("CD variation level");
ylabel("Mean failure rate");
title("DOE main effect: CD");

nexttile;
thEffect = groupsummary(T,"Thickness_Level","mean",["failure","p_defect"]);
plot(1:3,thEffect.mean_failure,"-o","LineWidth",1.5);
xticks(1:3); xticklabels(["Low","Medium","High"]);
xlabel("Thickness variation level");
ylabel("Mean failure rate");
title("DOE main effect: thickness");

exportgraphics(gcf,fullfile(outDir,"DOE_main_effects_failure.png"),"Resolution",220);

%% 2.4 Interaction plot
figure("Color","w");
hold on;
levels = ["Low","Medium","High"];

for i = 1:3
    idx = T.CD_Level == levels(i);
    tmp = groupsummary(T(idx,:),"Thickness_Level","mean","failure");
    plot(1:3,tmp.mean_failure,"-o","LineWidth",1.5, ...
        "DisplayName","CD "+levels(i));
end

xticks(1:3);
xticklabels(levels);
xlabel("Thickness variation level");
ylabel("Mean failure rate");
title("CD × thickness interaction");
legend("Location","best");
grid on;
exportgraphics(gcf,fullfile(outDir,"DOE_interaction_failure.png"),"Resolution",220);

%% 2.5 ANOVA: failure probability surrogate
% Because failure is binary, this ANOVA is descriptive. A logistic model is
% also fitted below as the preferred inferential model.

[pA,tblA,statsA] = anovan( ...
    T.failure, ...
    {T.CD_Level, T.Thickness_Level}, ...
    'model', 'interaction', ...
    'varnames', {'CD','Thickness'}, ...
    'display', 'off');

% Convert ANOVA cell output into a table
anovaFailure = cell2table(tblA(2:end,:), ...
    'VariableNames', matlab.lang.makeValidName(tblA(1,:)));

writetable(anovaFailure, ...
    fullfile(outDir,'DOE_ANOVA_failure.csv'));
%% 2.6 Logistic DOE model
glm = fitglm(T, ...
    "failure ~ CD_Code*Thickness_Code", ...
    "Distribution","binomial","Link","logit");

disp("Logistic DOE model:");
disp(glm);
writetable(glm.Coefficients,fullfile(outDir,"DOE_logistic_coefficients.csv"), ...
    "WriteRowNames",true);

%% 2.7 Response surface for predicted failure probability
[cdGrid,thGrid] = meshgrid(linspace(1,3,60),linspace(1,3,60));
Grid = table(cdGrid(:),thGrid(:), ...
    "VariableNames",["CD_Code","Thickness_Code"]);

Grid.PredFailure = predict(glm,Grid);
Z = reshape(Grid.PredFailure,size(cdGrid));

figure("Color","w");
surf(cdGrid,thGrid,Z,"EdgeColor","none");
xlabel("CD level code");
ylabel("Thickness level code");
zlabel("Predicted failure probability");
title("DOE response surface");
colorbar;
view(135,30);
exportgraphics(gcf,fullfile(outDir,"DOE_response_surface.png"),"Resolution",220);

%% 2.8 Identify lowest predicted-risk combination
[minRisk,idxMin] = min(Grid.PredFailure);
bestCD = Grid.CD_Code(idxMin);
bestTH = Grid.Thickness_Code(idxMin);

fprintf("\nLowest predicted failure risk in DOE grid = %.5f\n",minRisk);
fprintf("CD level code = %.0f; Thickness level code = %.0f\n",bestCD,bestTH);

optimum = table(bestCD,bestTH,minRisk, ...
    "VariableNames",["CD_Level_Code","Thickness_Level_Code","PredictedFailure"]);
writetable(optimum,fullfile(outDir,"DOE_optimum.csv"));

%% ========================================================================
% 3. SPC
% =========================================================================

% SPC is performed by creating ordered subgroups from wafer-site records.
% If lot/wafer/time sequence exists in a future version of the dataset,
% that sequence should replace row order.

T.Order = (1:height(T))';

% Five observations per subgroup.
subgroupSize = 5;
T.Subgroup = ceil(T.Order/subgroupSize);

% Remove incomplete final subgroup for Xbar/R calculations.
nComplete = floor(height(T)/subgroupSize)*subgroupSize;
S = T(1:nComplete,:);

%% 3.1 X-bar and R chart for CD
[G2,sub] = findgroups(S.Subgroup);
xbar = splitapply(@mean,S.cd,G2);
R = splitapply(@(x) max(x)-min(x),S.cd,G2);

xbarbar = mean(xbar);
Rbar = mean(R);

d2 = 2.326; % subgroup size n=5
D3 = 0;
D4 = 2.282;

UCLx = xbarbar + 3*Rbar/(d2*sqrt(subgroupSize));
LCLx = xbarbar - 3*Rbar/(d2*sqrt(subgroupSize));

UCLr = D4*Rbar;
LCLr = D3*Rbar;

figure("Color","w");
plot(sub,xbar,"-o","LineWidth",1.0); hold on;
yline(xbarbar,"-","CL");
yline(UCLx,"--","UCL");
yline(LCLx,"--","LCL");
xlabel("Subgroup");
ylabel("Mean CD");
title("X-bar chart — critical dimension");
grid on;
exportgraphics(gcf,fullfile(outDir,"SPC_Xbar_CD.png"),"Resolution",220);

figure("Color","w");
plot(sub,R,"-o","LineWidth",1.0); hold on;
yline(Rbar,"-","CL");
yline(UCLr,"--","UCL");
yline(LCLr,"--","LCL");
xlabel("Subgroup");
ylabel("Range of CD");
title("R chart — critical dimension");
grid on;
exportgraphics(gcf,fullfile(outDir,"SPC_R_CD.png"),"Resolution",220);

%% 3.2 Capability indices for CD
muCD = mean(S.cd);
sigmaWithin = Rbar/d2;

% Project specification limits.
% These are deliberately configurable and must be replaced if an actual
% engineering specification is supplied.
LSL_CD = min(S.cd);
USL_CD = max(S.cd);

Cp = (USL_CD-LSL_CD)/(6*sigmaWithin);
Cpk = min((USL_CD-muCD)/(3*sigmaWithin), ...
          (muCD-LSL_CD)/(3*sigmaWithin));

capability = table(muCD,sigmaWithin,LSL_CD,USL_CD,Cp,Cpk, ...
    "VariableNames",["MeanCD","WithinSigma","LSL","USL","Cp","Cpk"]);
writetable(capability,fullfile(outDir,"SPC_CD_capability.csv"));

%% 3.3 p-chart for wafer-site failure
% Treat each subgroup as n=5 inspected sites.
failCount = splitapply(@sum,S.failure,G2);
n = splitapply(@numel,S.failure,G2);
p_i = failCount./n;
pbar = sum(failCount)/sum(n);

UCLp = pbar + 3*sqrt(pbar*(1-pbar)./n);
LCLp = max(0,pbar - 3*sqrt(pbar*(1-pbar)./n));

figure("Color","w");
plot(sub,p_i,"-o","LineWidth",1.0); hold on;
yline(pbar,"-","CL");
plot(sub,UCLp,"--","DisplayName","UCL");
plot(sub,LCLp,"--","DisplayName","LCL");
xlabel("Subgroup");
ylabel("Failure proportion");
title("p-chart — site failure");
legend("Failure proportion","Center line","UCL","LCL","Location","best");
grid on;
exportgraphics(gcf,fullfile(outDir,"SPC_p_chart_failure.png"),"Resolution",220);

%% 3.4 Thickness X-bar/R chart
xbarT = splitapply(@mean,S.thickness,G2);
RT = splitapply(@(x) max(x)-min(x),S.thickness,G2);

xbarbarT = mean(xbarT);
RbarT = mean(RT);

UCLxT = xbarbarT + 3*RbarT/(d2*sqrt(subgroupSize));
LCLxT = xbarbarT - 3*RbarT/(d2*sqrt(subgroupSize));

UCLR_T = D4*RbarT;
LCLR_T = D3*RbarT;

figure("Color","w");
plot(sub,xbarT,"-o","LineWidth",1.0); hold on;
yline(xbarbarT,"-","CL");
yline(UCLxT,"--","UCL");
yline(LCLxT,"--","LCL");
xlabel("Subgroup");
ylabel("Mean thickness");
title("X-bar chart — film thickness");
grid on;
exportgraphics(gcf,fullfile(outDir,"SPC_Xbar_Thickness.png"),"Resolution",220);

figure("Color","w");
plot(sub,RT,"-o","LineWidth",1.0); hold on;
yline(RbarT,"-","CL");
yline(UCLR_T,"--","UCL");
yline(LCLR_T,"--","LCL");
xlabel("Subgroup");
ylabel("Range of thickness");
title("R chart — film thickness");
grid on;
exportgraphics(gcf,fullfile(outDir,"SPC_R_Thickness.png"),"Resolution",220);

%% 3.5 SPC signal detection
cdOut = (xbar > UCLx | xbar < LCLx);
rOut = (R > UCLr | R < LCLr);
pOut = (p_i > UCLp | p_i < LCLp);

signals = table(sub,cdOut,rOut,pOut, ...
    "VariableNames",["Subgroup","CD_Xbar_OutOfControl", ...
                     "CD_R_OutOfControl","Failure_p_OutOfControl"]);
writetable(signals,fullfile(outDir,"SPC_signals.csv"));

fprintf("\nSPC summary\n");
fprintf("CD X-bar out-of-control subgroups: %d\n",sum(cdOut));
fprintf("CD R-chart out-of-control subgroups: %d\n",sum(rOut));
fprintf("Failure p-chart out-of-control subgroups: %d\n",sum(pOut));

%% 3.6 Save complete workspace
save(fullfile(outDir,"ELWVB_DOE_SPC_workspace.mat"));

fprintf("\nDOE and SPC analysis complete.\n");
fprintf("Results saved in: %s\n",outDir);
