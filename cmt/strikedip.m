function [strike,dip]=strikedip(varargin)
%STRIKEDIP    Returns strike & dip given normal vector to plane
%
%    Usage:
%
%    Description:
%
%    Notes:
%
%    Examples:
%
%    See also:

%     Version History:
%        Mar.  8, 2010 - initial version
%
%     Written by Garrett Euler (ggeuler at wustl dot edu)
%     Last Updated Mar.  8, 2010 at 13:50 GMT

% todo:

% conversion
R2D=180/pi;

if(nargin==1)
    % check input
    sz=size(varargin{1});
    if(~isreal(varargin{1}) || ~isequal(3,sz(2)))
        error('seizmo:strikedip:badInput',...
            'NEU must be a real-valued Nx3 array!');
    end
    
    % make sure normals are always pointing up at hanging block
    % - reflect if not
    j=find(varargin{1}(:,3)<0);
    varargin{1}(j,:)=-varargin{1}(j,:);

    % get strike
    strike=atan2(varargin{1}(:,2),varargin{1}(:,1))*R2D-90;
    strike=mod(strike,360);

    % get dip
    dip=atan2(sqrt(varargin{1}(:,1).^2+varargin{1}(:,2).^2),varargin{1}(:,3))*R2D;
elseif(nargin==3)
    % check inputs
    if(any(~cellfun('isreal',varargin) | cellfun('size',varargin,2)~=1))
        error('seizmo:strikedip:badInput',...
            'All inputs must be real-valued Nx1 vectors!');
    end
    
    % expand scalars
    n=cellfun('prodofsize',varargin);
    sz=size(varargin{find(n==max(n),1,'first')});
    for i=1:3
        if(n(i)==1)
            varargin{i}=varargin{i}(ones(sz));
        else
            if(~isequal(size(varargin{i}),sz))
                error('seizmo:strikedip:badInput',...
                    'Non-scalar inputs must be equal sized!');
            end
        end
    end
    
    % make sure normals are always pointing up at hanging block
    % - reflect if not
    j=find(varargin{3}<0);
    varargin{1}(j)=-varargin{1}(j);
    varargin{2}(j)=-varargin{2}(j);
    varargin{3}(j)=-varargin{3}(j);

    % get strike
    strike=atan2(varargin{2},varargin{1})*R2D-90;
    strike=mod(strike,360);

    % get dip
    dip=atan2(sqrt(varargin{1}.^2+varargin{2}.^2),varargin{3})*R2D;
else
    error('seizmo:strikedip:badNumInputs',...
        'Incorrect number of inputs!');
end

% split up if wanted
if(nargout<=1)
    strike=cat(2,strike,dip);
elseif(nargout==2)
    % already done
else
    error('seizmo:strikedip:badNumOutputs',...
        'Incorrect number of outputs!');
end

end
