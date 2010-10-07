function [corrections]=cmb_corrections(phase,data)
%CMB_CORRECTIONS    Gets travel time and amplitude corrections
%
%    Usage:    corrections=cmb_corrections(phase,data)

% todo:

% check nargin
error(nargchk(2,2,nargin));

% check phase
valid={'Pdiff' 'SHdiff' 'SVdiff'};
if(~isstring(phase) || ~ismember(phase,valid))
    error('seizmo:cmb_corrections:badPhase',...
        ['PHASE must be one of the following:\n' ...
        sprintf('''%s'' ',valid{:}) '!']);
end

% check data
error(seizmocheck(data));

% necessary header info
% ev - evla evlo evel evdp
% st - stla stlo stel stdp
% delaz - gcarc az baz dist
[ev,delaz,st]=getheader(data,'ev','delaz','st');

% convert meters to kilometers
ev(:,3:4)=ev(:,3:4)/1000;
st(:,3:4)=st(:,3:4)/1000;

% operation depends on phase
switch phase
    case 'Pdiff'
        % get ellipticity corrections
        corrections.ellcor=ellcor(ev(:,1),ev(:,4),delaz(:,1),delaz(:,2),'Pdiff');
        
        % get crustal corrections
        rayp=4.42802574759071;
        corrections.crucor.prem=crucor(st(:,1),st(:,2),rayp,'P',...
            'elev',st(:,3),'hole',st(:,4),'refmod','prem');
        corrections.crucor.ak135=crucor(st(:,1),st(:,2),rayp,'P',...
            'elev',st(:,3),'hole',st(:,4),'refmod','ak135');
        corrections.crucor.iasp91=crucor(st(:,1),st(:,2),rayp,'P',...
            'elev',st(:,3),'hole',st(:,4),'refmod','iasp91');
        
        % get Sdiff raypaths
        paths=getraypaths('P,Pdiff','prem',ev(:,1),ev(:,2),ev(:,4),st(:,1),st(:,2));
        
        % remove crust from paths
        paths=crust2less_raypaths(paths);
        
        % upswing paths
        % - using 500km above CMB as the cutoff
        uppaths=extract_upswing_raypaths(paths,2890-500);
        
        % mantle corrections
        corrections.mancor.hmsl06p.full=mancor(paths,'hmsl06p');
        corrections.mancor.hmsl06p.upswing=mancor(uppaths,'hmsl06p');
        corrections.mancor.mitp08.full=mancor(paths,'mit-p08');
        corrections.mancor.mitp08.upswing=mancor(uppaths,'mit-p08');
        corrections.mancor.dz04.full=mancor(paths,'dz04');
        corrections.mancor.dz04.upswing=mancor(uppaths,'dz04');
        %corrections.mancor.prip05.full=mancor(paths,'pri-p05');
        %corrections.mancor.prip05.upswing=mancor(uppaths,'pri-p05');
    case {'Sdiff' 'SHdiff' 'SVdiff'}
        % get ellipticity corrections
        corrections.ellcor=ellcor(ev(:,1),ev(:,4),delaz(:,1),delaz(:,2),'Sdiff');
        
        % get crustal corrections
        rayp=8.36067454903639;
        corrections.crucor.prem=crucor(st(:,1),st(:,2),rayp,'S',...
            'elev',st(:,3),'hole',st(:,4),'refmod','prem');
        corrections.crucor.ak135=crucor(st(:,1),st(:,2),rayp,'S',...
            'elev',st(:,3),'hole',st(:,4),'refmod','ak135');
        corrections.crucor.iasp91=crucor(st(:,1),st(:,2),rayp,'S',...
            'elev',st(:,3),'hole',st(:,4),'refmod','iasp91');
        
        % get Sdiff raypaths
        paths=getraypaths('S,Sdiff','prem',ev(:,1),ev(:,2),ev(:,4),st(:,1),st(:,2));
        
        % remove crust from paths
        paths=crust2less_raypaths(paths);
        
        % upswing paths
        % - using 500km above CMB as the cutoff
        uppaths=extract_upswing_raypaths(paths,2890-500);
        
        % mantle corrections
        corrections.mancor.hmsl06s.upswing=mancor(uppaths,'hmsl06s');
        corrections.mancor.hmsl06s.full=mancor(paths,'hmsl06s');
        corrections.mancor.s20rts.upswing=mancor(uppaths,'s20rts');
        corrections.mancor.s20rts.full=mancor(paths,'s20rts');
        corrections.mancor.saw24b16.upswing=mancor(uppaths,'saw24b16');
        corrections.mancor.saw24b16.full=mancor(paths,'saw24b16');
        corrections.mancor.sb4l18.upswing=mancor(uppaths,'sb4l18');
        corrections.mancor.sb4l18.full=mancor(paths,'sb4l18');
        corrections.mancor.tx2007.upswing=mancor(uppaths,'tx2007');
        corrections.mancor.tx2007.full=mancor(paths,'tx2007');
        %corrections.mancor.pris05.full=mancor(paths,'pri-s05');
        %corrections.mancor.pris05.upswing=mancor(uppaths,'pri-s05');
end

% get geometrical spreading corrections
corrections.geomsprcor=geomsprcor(delaz(1));

end
