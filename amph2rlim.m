function [data]=amph2rlim(data)
%AMPH2RLIM    Convert SEIZMO spectral records from AMPH to RLIM
%
%    Usage:    data=amph2rlim(data)
%
%    Description: AMPH2RLIM(DATA) converts SEIZMO amplitude-phase records 
%     to real-imaginary records.  This is particularly useful when
%     performing basic operations on spectral records which would otherwise
%     require treating the amplitude and phase components separately.
%     Records in DATA must be of the spectral variety.  Real-imaginary
%     records are not altered.
%
%    Notes:
%
%    Header changes: IFTYPE, DEPMEN, DEPMIN, DEPMAX
%
%    Examples:
%     To simply multiply two records in the frequency domain, they must be
%     converted to real-imaginary first:
%      data=amph2rlim(data)
%      data=multiplyrecords(data(1),data(2))
%      data=rlim2amph(data)
%
%    See also: RLIM2AMPH, DFT, IDFT

%     Version History:
%        June 11, 2008 - initial version
%        June 20, 2008 - minor doc update
%        June 28, 2008 - fixed call to ch, removed option,
%                        doc update, .dep rather than .x
%        July 19, 2008 - dataless support, updates DEP* fields
%        Oct.  7, 2008 - minor code cleaning
%        Nov. 22, 2008 - update for new name schema
%        Apr. 23, 2009 - fix nargchk and seizmocheck for octave,
%                        move usage up
%        Oct. 21, 2009 - only touches amph (maybe a bit faster)
%        Dec.  4, 2009 - fixed IFTYPE bug, handle no amph case
%        Jan. 26, 2010 - seizmoverbose support
%        Feb.  2, 2010 - versioninfo caching (required some code changes)
%        Mar.  8, 2010 - versioninfo caching dropped
%
%     Written by Garrett Euler (ggeuler at wustl dot edu)
%     Last Updated Mar.  8, 2010 at 12:45 GMT

% todo:

% check nargin
msg=nargchk(1,1,nargin);
if(~isempty(msg)); error(msg); end

% check data structure
versioninfo(data,'dep');

% turn off struct checking
oldseizmocheckstate=seizmocheck_state(false);

% attempt conversion
try
    % check header (versioninfo cache update)
    data=checkheader(data);
    
    % verbosity
    verbose=seizmoverbose;
    
    % number of records
    nrecs=numel(data);
    
    % retreive header info
    iftype=getenumid(data,'iftype');

    % find spectral
    amph=strcmpi(iftype,'iamph');
    rlim=strcmpi(iftype,'irlim');

    % records must be spectral
    if(any(~amph & ~rlim))
        error('seizmo:amph2rlim:illegalOperation',...
            ['Record(s):\n' sprintf('%d ',find(~amph & ~rlim)) ...
            '\nIllegal operation on non-spectral record(s)!']);
    end
    
    % detail message
    if(verbose)
        disp('Converting AMPH Record(s) to RLIM');
        print_time_left(0,nrecs);
    end
    
    % loop through records
    depmen=nan(nrecs,1); depmin=depmen; depmax=depmen;
    for i=1:nrecs
        % skip dataless
        if(isempty(data(i).dep))
            % detail message
            if(verbose); print_time_left(i,nrecs); end
            continue;
        end

        % convert amph
        if(amph(i))
            oclass=str2func(class(data(i).dep));
            data(i).dep=double(data(i).dep);
            temp=data(i).dep(:,1:2:end).*exp(j*data(i).dep(:,2:2:end));
            data(i).dep(:,1:2:end)=real(temp);
            data(i).dep(:,2:2:end)=imag(temp);
            data(i).dep=oclass(data(i).dep);
        end

        % dep*
        depmen(i)=mean(data(i).dep(:));
        depmin(i)=min(data(i).dep(:));
        depmax(i)=max(data(i).dep(:));
        
        % detail message
        if(verbose); print_time_left(i,nrecs); end
    end

    % update filetype
    data=changeheader(data,'iftype','irlim',...
        'depmax',depmax,'depmin',depmin,'depmen',depmen);

    % toggle checking back
    seizmocheck_state(oldseizmocheckstate);
catch
    % toggle checking back
    seizmocheck_state(oldseizmocheckstate);
    
    % rethrow error
    error(lasterror)
end

end
