function BoseOne(task)                        %%name of main function

% This script calls the trap axis x in order to plot 1D graphs along
% it. The bisection axis is called y.  The graph labels match my thesis.

% The intent is to call the function on the supercomputer to save an HDF file, then on a terminal to plot the grphs.  This is determined by the input argument: 'compute' generates data, 'plot' does graphs.  The default is to do both.


gr1.xlabels = {'t', 'z', 'x'};

global cfs,  load cfs

tmax = 5;

icond.name =		'two dimensional Vienna trap, imaginary time initial state';
icond.dimension =	3;
icond.fields =		1; 
icond.ranges =		[tmax,200,6];
icond.cfs =		cfs([1 2 3 5], :);  % quartics.  column i has coefs of [y^4 1 y^2 x^2] at t/ms = i-1
icond.points =		[49 70 27];
% icond.order =		0;
icond.steps =		20*tmax;
icond.step =		@nrmstp;
icond.initial =		@(w,r) ones(size(r.x));
icond.da =		@Da;
icond.linear =		@(D,r) 0.5*(D.x.^2 + D.y.^2); 
% icond.observe =	@(a,~,~) abs(a).^2;
icond.ensembles =	[30 3 32];

gr1.images =		[0];
gr1.olabels =		{'<|\psi|^2>'};

monte = icond;
monte.name =		'two dimensional Vienna trap splitting';
monte.seed =		29101977;
monte.noises =		[2 0];	% Re and Im
monte.transfer =	@(w,r,a0,r0) a0 + [1 1i]*w/2;
monte.da =		@Db;
monte.linear =		@(D,r) 0.5*1i*(D.x.^2 + D.y.^2); 
monte.step =		@xMP;
monte.ranges =	[17/1.368,200,6];
monte.steps =		100;
monte.HDF5file =	'BoseOut.h5';

gr2 = gr1;
% gr2.images =		[5 0 0 0 0 0 0];
% gr2.transverse =	[0 0 0 0 5 5 5];

% monte.observe{1} =	@(a,r) abs(a).^2 - 1/(2*r.dV);
% gr2.olabels{1} =		{'n'};

% monte.observe{2} =	@(a,r) angle(aone(a,r,+1));
% gr2.olabels{2} =		{'\phi_R'};

% monte.observe{3} =	@(a,r) angle(aone(a,r,-1));
% gr2.olabels{3} =		{'\phi_L'};

% monte.observe{4} =	@(a,r) angle(conj(aone(a,r,+1)).*aone(a,r,-1));
% gr2.olabels{4} =		{'\phi_-'};

% % number correlation observables

% monte.observe{5} =	@(a,r) dens(a,r,-1);
% gr2.olabels{5} =		{'n_l'};

% monte.observe{6} =	@(a,r) dens(a,r,+1);
% gr2.olabels{6} =		{'n_r'};

% monte.observe{7} =	@vnce;
% gr2.olabels{7} =		{':(n_r-n_l)^2:'};

% Total number observables.  A significant number of particles lies at r.y==0, and we count half of these on each side

monte.observe{1} =	@(a,r)  xint(((r.y<0)+0.5*(r.y==0)).*(abs(a).^2-1/(2*r.dV)), r, r.dx);
gr2.olabels{1} =		{'N_l'};

monte.observe{2} =	@(a,r)  xint(((r.y>0)+0.5*(r.y==0)).*(abs(a).^2-1/(2*r.dV)), r, r.dx);
gr2.olabels{2} =		{'N_r'};

monte.observe{3} = @(a,r) xint(sign(r.y).*(abs(a).^2-1/(2*r.dV)), r, r.dx).^2 - prod(r.points(2:end))/4;
gr2.olabels{3} =		{'<(N_r-N_l)^2>'};

monte.observe{4} =	@(a,r)  xint(abs(a).^2-1/(2*r.dV), r, r.dx);
gr2.olabels{4} =		{'N'};

gr2.pdimension =	ones(size(monte.observe));

if nargin == 0 || strcmp(task, 'compute')
	parpool(monte.ensembles(end))
	xsim({icond, monte})
end

if nargin == 0 || strcmp(task, 'plot')
	xgraph({''}, monte, gr2)
end

end	% function BoseOne

function b = nrmstp(a,r,xi,dt)
	b = xMP(a,r,xi,dt);
	s = xint(abs(b).^2, r, r.dx);
	b = sqrt(7000./s).*b;
end

function o = dens(a,r,side)
	m = r.dx;  m(2) = 0;	% IWRT y
	I = (side*r.y<0).*(abs(a).^2-1/(2*r.dV));
	o = xint(I, r, m);
end

function o = vnce(a,r)
	m = r.dx;  m(2) = 0;	% IWRT y
	I = sign(r.y).*(abs(a).^2-1/(2*r.dV));
	II = (abs(a).^2-1/(4*r.dV))/r.dx(2);
	o = xint(I, r, m).^2 - xint(II, r, m);
end

function f = aone(a,r,dn)
	m = r.dx;
	m(2) = 0;	% IWRT y
	f = xint(a.*(dn*r.y > 0), r, m);
end

function c = crln(o,r,in)	% 1D autocorrelation
	o = o(r.y == r.y(1));	% take a line from the plane
	n = length(o);
	c = toeplitz(o, [o(1) zeros(1, n-1)])' * o(:) * in.dx(2);
	% FIXME: repeat with correct shape
end

% FIXME D.R.Y.

function da  =  Da(a,r,~)
	K = [r.y(:).^4 ones(size(r.x(:))) r.y(:).^2 r.x(:).^2]*r.cfs(:, 1);
	K = reshape(K, size(r.x));
	K = min(K, 100);		% trim unphysical part from quartic fit
	da = -0.5*(K + 0.2255*abs(a).^2).*a;
end

function da  =  Db(a,r,~)
	ts = (0:17)/1.368;
	c = interp1(ts, r.cfs', r.t)';
	K = [r.y(:).^4 ones(size(r.x(:))) r.y(:).^2 r.x(:).^2]*c;
	K = reshape(K, size(r.x));
	K = min(K, 100);		% trim unphysical part from quartic fit
	da = -0.5*1i*(K + 0.2255*abs(a).^2).*a;
end
