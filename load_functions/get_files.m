

% MAGNETIC DATA------------------------------------------------------------

%bFilePath = '/Volumes/GoogleDrive/My Drive/Work/Projects/GIC/000_DATA/MAG_DATA/20170908';
%bFile = '20170908_cleaned.mat';

%bFilePath = '/Volumes/GoogleDrive/My Drive/Work/Projects/GIC/000_DATA/MAG_DATA/20211012';
%bFile = '20211012_cleaned.mat';
% 
%bFilePath = '/Users/darcycordell/Library/CloudStorage/GoogleDrive-dcordell@ualberta.ca/My Drive/Work/Projects/GIC/000_DATA/MAG_DATA/20230323';
%bFile = '20230323_24_cleaned.mat';

%bFilePath = '/Users/darcycordell/Library/CloudStorage/GoogleDrive-dcordell@ualberta.ca/My Drive/Work/Projects/GIC/000_DATA/MAG_DATA/20211104';
%bFile = '20211104_edit_v_20230525.mat';

%bFilePath = 'D:/OneDrive - University of Alberta/Documents/Summer Research_Space Weather/ABGIC - Copy';
% bFile = '20240510_edit_v_20241114.mat';


% IMPEDANCE DATA------------------------------------------------------------

% zFilePath = 'D:/OneDrive - University of Alberta/Documents/Summer Research_Space Weather/ABGIC - Copy';
% zFile = 'gic_fwd_run02.mat';

%zFilePath = '/Users/darcycordell/Documents/GitHub/ABGIC/000_DATA/05_MT_IMPEDANCE';
%zFile = 'AB_BC_MT_DATA_526_sites_230321.mat';



% NETWORK DATA------------------------------------------------------------

% networkFilePath = 'D:/OneDrive - University of Alberta/Documents/Summer Research_Space Weather/ABGIC - Copy';
% lineFile = 'LINES_240116.mat';
% subFile = 'SUBS_240116.mat';
% tranFile = 'TRANS_240508.mat';

%lineFile = 'LINES.mat';
%tranFile = 'TRANS_HORTON.mat';


% HALL PROBE DATA------------------------------------------------------------

hallFilePath = '/Users/darcycordell/Library/CloudStorage/GoogleDrive-dcordell@ualberta.ca/My Drive/Work/Projects/GIC/000_DATA/Hall_AltaLink';

%hallFile = 'AltaLink_GIC_230322_25_merge.xlsx';
hallFile = 'AltaLink_GIC_230422_24_merge.xlsx';
%hallFile = 'AltaLink_GIC_211012.csv';
%hallFile = 'AltaLink_GIC_211104.csv';

uniform=0;


% bFile = load(MagneticFile);     % loads struct with variable `b`
zFile = load(zFile);    % loads struct with variable `Z`
lineFile = load(lineFile);      % loads struct with `L`
subFile = load(subFile);        % loads struct with `S`
tranFile = load(transFile);     % loads struct with `T`
