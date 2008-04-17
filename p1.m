function [fh,sfh]=p1(data,varargin)
%P1    Plot SAClab data records in individual subplots
%
%    Description: Plots timeseries and xy SAClab records in individual
%     subplots.  Other filetypes are ignored (a space is left in the figure
%     though).  Flags for 'o','a','f','t(n)' are drawn if defined.  Labels
%     are drawn for the flags using 'ko','ka','kf','kt(n)' if defined or
%     the field name (o,a,f,t(n)).  Optional inputs should correspond to 
%     fields returned by function pconf.  Output is the figure and 
%     subfigure handles.
% 
%    Usage:  [fh,sfh]=p1(data,'plot_option',plot_option_value,...)
%
%    Examples:
%     Plot records with 3 columns of subplots
%        p1(data,'ncols',3)
%
%    See also:  p2, p3, recsec

% check data structure
error(seischk(data,'x'))

% get plotting style defaults
P=pconf;

% allow access to plot styling using global SACLAB structure
global SACLAB; fields=fieldnames(P).';
for i=fields; if(isfield(SACLAB,i)); P.(i{:})=SACLAB.(i{:}); end; end

% sort out optional arguments
for i=1:2:length(varargin)
    % plotting parameter field
    varargin{i}=upper(varargin{i});
    if(isfield(P,varargin{i}))
        P.(varargin{i})=varargin{i+1};
    else
        warning('SAClab:p1:badInput','Unknown Option: %s',varargin{i}); 
    end
end

% clean up unset parameters
P=pconffix(P);

% select/open plot
if(isempty(P.FIGHANDLE) || P.FIGHANDLE<1)
    fh=figure;
else
    fh=figure(P.FIGHANDLE);
end

% SOME STYLING OF THE PLOT
set(gcf,'name',['P1 -- ' P.NAME],...
        'numbertitle',P.NUMBERTITLE,...
        'menubar',P.MENUBAR,...
        'toolbar',P.TOOLBAR,...
        'renderer',P.RENDERER,...
        'renderermode',P.RENDERERMODE,...
        'doublebuffer',P.DOUBLEBUFFER,...
        'color',P.FIGBGCOLOR,...
        'pointer',P.POINTER);

% number of records
nrecs=length(data);

% record coloring
try
    % try using as a colormap function
    cmap=str2func(P.COLORMAP);
    colors=cmap(nrecs);
catch
    % otherwise its a color array/string
    colors=repmat(P.COLORMAP,ceil(nrecs/size(P.COLORMAP,1)),1);
end

% header info
leven=glgc(data,'leven');
error(lgcchk('leven',leven))
iftype=genumdesc(data,'iftype');
[t,kt,o,ko,a,ka,f,kf,b,delta,npts,gcarc]=...
    gh(data,'t','kt','o','ko','a','ka','f','kf',...
    'b','delta','npts','gcarc');

% header structures (for determining if undefined)
vers=unique([data.version]);
nver=length(vers);
h(nver)=seishi(vers(nver));
for i=1:nver-1
    h(i)=seishi(vers(i));
end

% default columns/rows
if(isempty(P.NCOLS))
    P.NCOLS=fix(sqrt(nrecs));
    nrows=ceil(nrecs/P.NCOLS);
else
    nrows=ceil(nrecs/P.NCOLS);
end

% force x/y limits into individual subplot control
if(~isempty(P.XLIMITS))
    P.XLIMITS=repmat(P.XLIMITS,ceil(nrecs/size(P.XLIMITS,1)),1);
end
if(~isempty(P.YLIMITS))
    P.YLIMITS=repmat(P.XLIMITS,ceil(nrecs/size(P.XLIMITS,1)),1);
end

% loop through each record
sfh=zeros(nrecs,1);
for i=1:nrecs
    % header version
    v=(data(i).version==vers);
    
    % check if timeseries or xy (if not skip)
    if(~any(strcmp(iftype(i),{'Time Series File' ...
            'General X vs Y file'})))
        continue; 
    end
    
    % get record timing
    if(strcmp(leven(i),'true'))
        time=b(i)+(0:npts(i)-1).'*delta(i);
    else
        time=data(i).t; 
    end
    
    % focus to new subplot and draw record
    sfh(i)=subplot(nrows,P.NCOLS,i);
    plot(time,data(i).x,'color',colors(i,:),'linewidth',P.RECWIDTH);
    set(gca,'fontname',P.AXISFONT,'fontweight',P.AXISFONTWEIGHT,...
        'fontsize',P.AXISFONTSIZE,'box',P.BOX,...
        'xcolor',P.XAXISCOLOR,'ycolor',P.YAXISCOLOR,...
        'xaxislocation',P.XAXISLOCATION,'yaxislocation',P.YAXISLOCATION,...
        'tickdir',P.TICKDIR,'ticklength',P.TICKLEN,...
        'linewidth',P.AXISLINEWIDTH,'color',P.PLOTBGCOLOR,...
        'xminortick',P.XMINORTICK,'yminortick',P.YMINORTICK);
    grid(P.GRID);
    
    % zooming
    axis(P.AXIS{:});
    if(~isempty(P.XLIMITS)); axis auto; xlim(P.XLIMITS(i,:)); end
    if(~isempty(P.YLIMITS)); ylim(P.YLIMITS(i,:)); end
    
    % scaling parameters for header flags
    fylimits=get(gca,'ylim');
    fxlimits=get(gca,'xlim');
    yrange=fylimits(2)-fylimits(1);
    xrange=fxlimits(2)-fxlimits(1);
    ypad=P.MARKYPAD*yrange;  % these are simplistic - really you will have to
    xpad=P.MARKXPAD*xrange;  % adjust these based on your font and plot size
    
    % axis labels
    if(isempty(P.TITLE))
        if(isfield(data,'name') && ~isempty(data(i).name))
            P.TITLE=[texlabel(data(i).name,'literal') ...
                '  -  ' num2str(gcarc(i)) '\circ'];
        else P.TITLE=['RECORD ' num2str(i) ...
                '  -  ' num2str(gcarc(i)) '\circ'];
        end
    end
    %if(isempty(P.XLABEL)); P.XLABEL='Time (sec)'; end
    %if(isempty(P.YLABEL)); P.YLABEL='Amplitude'; end
    title(P.TITLE,'fontname',P.TITLEFONT,'fontweight',P.TITLEFONTWEIGHT,...
        'fontsize',P.TITLEFONTSIZE,'color',P.TITLEFONTCOLOR,...
        'interpreter',P.TITLEINTERP);
    xlabel(P.XLABEL,'fontname',P.XLABELFONT,'fontweight',P.XLABELFONTWEIGHT,...
        'fontsize',P.XLABELFONTSIZE,'color',P.XLABELFONTCOLOR,...
        'interpreter',P.XLABELINTERP);
    ylabel(P.YLABEL,'fontname',P.YLABELFONT,'fontweight',P.YLABELFONTWEIGHT,...
        'fontsize',P.YLABELFONTSIZE,'color',P.YLABELFONTCOLOR,...
        'interpreter',P.YLABELINTERP);
    
    % skip markers
    if(~P.MARKERS); continue; end
    
    % plot origin flag
    hold on
    if(o(i)~=h(v).undef.ntype)
        plot([o(i) o(i)].',[fylimits(1)+ypad fylimits(2)-2*ypad].',...
            'color',P.OCOLOR,'linewidth',P.MARKERWIDTH);
        if(P.MARKERLABELS)
            if(~strcmp(ko{i},h(v).undef.stype))
                text(o(i)+xpad,fylimits(2)-2*ypad,ko{i},'color',P.OCOLOR, ...
                    'fontname',P.MARKERFONT,'fontweight',P.MARKERFONTWEIGHT,...
                    'fontsize',P.MARKERFONTSIZE,'color',P.OMARKERFONTCOLOR,...
                    'verticalalignment','top','clipping','on');
            else
                text(o(i)+xpad,fylimits(2)-2*ypad,'o','color',P.OCOLOR, ...
                    'fontname',P.MARKERFONT,'fontweight',P.MARKERFONTWEIGHT,...
                    'fontsize',P.MARKERFONTSIZE,'color',P.OMARKERFONTCOLOR,...
                    'verticalalignment','top','clipping','on');
            end
        end
    end
    
    % plot arrival flag
    if(a(i)~=h(v).undef.ntype)
        plot([a(i) a(i)].',[fylimits(1)+ypad fylimits(2)-2*ypad].',...
            'color',P.ACOLOR,'linewidth',P.MARKERWIDTH);
        if(P.MARKERLABELS)
            if(~strcmp(ka{i},h(v).undef.stype))
                text(a(i)+xpad,fylimits(2)-2*ypad,ka{i},'color',P.ACOLOR, ...
                    'fontname',P.MARKERFONT,'fontweight',P.MARKERFONTWEIGHT,...
                    'fontsize',P.MARKERFONTSIZE,'color',P.AMARKERFONTCOLOR,...
                    'verticalalignment','top','clipping','on');
            else
                text(a(i)+xpad,fylimits(2)-2*ypad,'a','color',P.ACOLOR, ...
                    'fontname',P.MARKERFONT,'fontweight',P.MARKERFONTWEIGHT,...
                    'fontsize',P.MARKERFONTSIZE,'color',P.AMARKERFONTCOLOR,...
                    'verticalalignment','top','clipping','on');
            end
        end
    end
    
    % plot finish flag
    if(f(i)~=h(v).undef.ntype)
        plot([f(i) f(i)].',[fylimits(1)+ypad fylimits(2)-2*ypad].',...
            'color',P.FCOLOR,'linewidth',P.MARKERWIDTH);
        if(P.MARKERLABELS)
            if(~strcmp(kf{i},h(v).undef.stype))
                text(f(i)+xpad,fylimits(2)-2*ypad,kf{i},'color',P.FCOLOR, ...
                    'fontname',P.MARKERFONT,'fontweight',P.MARKERFONTWEIGHT,...
                    'fontsize',P.MARKERFONTSIZE,'color',P.FMARKERFONTCOLOR,...
                    'verticalalignment','top','clipping','on');
            else
                text(f(i)+xpad,fylimits(2)-2*ypad,'f','color',P.FCOLOR, ...
                    'fontname',P.MARKERFONT,'fontweight',P.MARKERFONTWEIGHT,...
                    'fontsize',P.MARKERFONTSIZE,'color',P.FMARKERFONTCOLOR,...
                    'verticalalignment','top','clipping','on');
            end
        end
    end
    
    % plot picks
    for j=0:9
        if(t(i,j+1)~=h(v).undef.ntype)
            plot([t(i,j+1) t(i,j+1)].',...
                [fylimits(1)+ypad fylimits(2)-(1+mod(j,5))*ypad].',...
                'color',P.TCOLOR,'linewidth',P.MARKERWIDTH)
            if(P.MARKERLABELS)
                if(~strcmp(kt{i,j+1},h(v).undef.stype))
                    text(t(i,j+1)+xpad,...
                        fylimits(2)-(1+mod(j,5))*ypad,kt{i,j+1},'color',P.TCOLOR,...
                        'fontname',P.MARKERFONT,'fontweight',P.MARKERFONTWEIGHT,...
                        'fontsize',P.MARKERFONTSIZE,'color',P.TMARKERFONTCOLOR,...
                        'verticalalignment','top','clipping','on');
                else
                    text(t(i,j+1)+xpad,...
                        fylimits(2)-(1+mod(j,5))*ypad,['t' num2str(j)],'color',P.TCOLOR,...
                        'fontname',P.MARKERFONT,'fontweight',P.MARKERFONTWEIGHT,...
                        'fontsize',P.MARKERFONTSIZE,'color',P.TMARKERFONTCOLOR,...
                        'verticalalignment','top','clipping','on');
                end
            end
        end
    end
    hold off
end

end
