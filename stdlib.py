# Standard imports for an environment like Matlab

# This doesn't import any interpolation routines: Python keeps reinventing that wheel, going from square to pentagonal to triangular.  See scipy.ndimage.interpolation and scipy.interpolate

from numpy import \
	abs, amax, amin, all, arange, argmax, array, \
	ceil, concatenate, diagflat, diagonal, dot, empty, eye, \
	floor, indices, isnan, linspace, \
	logical_not, logical_or, \
	mean, meshgrid, nan, ndarray, newaxis, nonzero, \
	pi, prod, ptp, \
	sign, sqrt, zeros, \
	exp, sin, cos, tan
from numpy.fft import fft, ifft, fftn, ifftn, fftfreq
from numpy.linalg import eig, norm, qr
from matplotlib.pyplot import colorbar, contour, contourf, figure, imshow, plot, savefig, subplot, text, title, xlabel, ylabel, xlim, ylim, xticks, yticks
import h5py
