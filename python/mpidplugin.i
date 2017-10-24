%module mpidplugin

%import(module="simtk.openmm") "swig/OpenMMSwigHeaders.i"
%include "swig/typemaps.i"

/*
 * The following lines are needed to handle std::vector.
 * Similar lines may be needed for vectors of vectors or
 * for other STL types like maps.
 */

%include "std_vector.i"
namespace std {
  %template(vectord) vector<double>;
  %template(vectori) vector<int>;
};

%{
#include "MPIDForce.h"
#include "OpenMM.h"
#include "OpenMMAmoeba.h"
#include "OpenMMDrude.h"
#include "openmm/RPMDIntegrator.h"
#include "openmm/RPMDMonteCarloBarostat.h"
%}

%pythoncode %{
import simtk.openmm as mm
import simtk.unit as unit
%}

/*
 * Add units to function outputs.
*/


namespace OpenMM {

class MPIDForce : public Force {

public:

    enum NonbondedMethod {

        /**
         * No cutoff is applied to nonbonded interactions.  The full set of N^2 interactions is computed exactly.
         * This necessarily means that periodic boundary conditions cannot be used.  This is the default.
         */
        NoCutoff = 0,

        /**
         * Periodic boundary conditions are used, and Particle-Mesh Ewald (PME) summation is used to compute the interaction of each particle
         * with all periodic copies of every other particle.
         */
        PME = 1
    };

    enum PolarizationType {

        /**
         * Full mutually induced polarization.  The dipoles are iterated until the converge to the accuracy specified
         * by getMutualInducedTargetEpsilon().
         */
        Mutual = 0,

        /**
         * Direct polarization approximation.  The induced dipoles depend only on the fixed multipoles, not on other
         * induced dipoles.
         */
        Direct = 1,

        /**
         * Extrapolated perturbation theory approximation.  The dipoles are iterated a few times, and then an analytic
         * approximation is used to extrapolate to the fully converged values.  Call setExtrapolationCoefficients()
         * to set the coefficients used for the extrapolation.  The default coefficients used in this release are
         * [-0.154, 0.017, 0.658, 0.474], but be aware that those may change in a future release.
         */
        Extrapolated = 2

    };

    enum MultipoleAxisTypes { ZThenX = 0, Bisector = 1, ZBisect = 2, ThreeFold = 3, ZOnly = 4, NoAxisType = 5, LastAxisTypeIndex = 6 };

    enum CovalentType {
                          Covalent12 = 0, Covalent13 = 1, Covalent14 = 2, Covalent15 = 3,
                          PolarizationCovalent11 = 4, PolarizationCovalent12 = 5, PolarizationCovalent13 = 6, PolarizationCovalent14 = 7, CovalentEnd = 8 };

    /**
     * Create an MPIDForce.
     */
    MPIDForce();

    /**
     * Get the number of particles in the potential function
     */
    int getNumMultipoles() const {
        return multipoles.size();
    }

    /**
     * Get the method used for handling long-range nonbonded interactions.
     */
    NonbondedMethod getNonbondedMethod() const;

    /**
     * Set the method used for handling long-range nonbonded interactions.
     */
    void setNonbondedMethod(NonbondedMethod method);

    /**
     * Get polarization type
     */
    PolarizationType getPolarizationType() const;

    /**
     * Set the polarization type
     */
    void setPolarizationType(PolarizationType type);

    /**
     * Get the cutoff distance (in nm) being used for nonbonded interactions.  If the NonbondedMethod in use
     * is NoCutoff, this value will have no effect.
     *
     * @return the cutoff distance, measured in nm
     */
    double getCutoffDistance() const;

    /**
     * Set the cutoff distance (in nm) being used for nonbonded interactions.  If the NonbondedMethod in use
     * is NoCutoff, this value will have no effect.
     *
     * @param distance    the cutoff distance, measured in nm
     */
    void setCutoffDistance(double distance);

    /**
     * Get the parameters to use for PME calculations.  If alpha is 0 (the default), these parameters are
     * ignored and instead their values are chosen based on the Ewald error tolerance.
     *
     * @param[out] alpha   the separation parameter
     * @param[out] nx      the number of grid points along the X axis
     * @param[out] ny      the number of grid points along the Y axis
     * @param[out] nz      the number of grid points along the Z axis
     */
    %apply double& OUTPUT {double& alpha};
    %apply int& OUTPUT {int& nx};
    %apply int& OUTPUT {int& ny};
    %apply int& OUTPUT {int& nz};
    void getPMEParameters(double& alpha, int& nx, int& ny, int& nz) const;
    %clear double& alpha;
    %clear int& nx;
    %clear int& ny;
    %clear int& nz;

    /**
     * Set the parameters to use for PME calculations.  If alpha is 0 (the default), these parameters are
     * ignored and instead their values are chosen based on the Ewald error tolerance.
     *
     * @param alpha   the separation parameter
     * @param nx      the number of grid points along the X axis
     * @param ny      the number of grid points along the Y axis
     * @param nz      the number of grid points along the Z axis
     */
    void setPMEParameters(double alpha, int nx, int ny, int nz);

    /**
     * Get the Ewald alpha parameter.  If this is 0 (the default), a value is chosen automatically
     * based on the Ewald error tolerance.
     *
     * @return the Ewald alpha parameter
     * @deprecated This method exists only for backward compatibility.  Use getPMEParameters() instead.
     */
    double getAEwald() const;

    /**
     * Set the Ewald alpha parameter.  If this is 0 (the default), a value is chosen automatically
     * based on the Ewald error tolerance.
     *
     * @param aewald alpha parameter
     * @deprecated This method exists only for backward compatibility.  Use setPMEParameters() instead.
     */
    void setAEwald(double aewald);

    /**
     * Get the B-spline order to use for PME charge spreading
     *
     * @return the B-spline order
     */
    int getPmeBSplineOrder() const;

    /**
     * Get the PME grid dimensions.  If Ewald alpha is 0 (the default), this is ignored and grid dimensions
     * are chosen automatically based on the Ewald error tolerance.
     *
     * @return the PME grid dimensions
     * @deprecated This method exists only for backward compatibility.  Use getPMEParameters() instead.
     */

    %apply std::vector<int>& OUTPUT {std::vector<int>& gridDimension};
    void getPmeGridDimensions(std::vector<int>& gridDimension) const;
    %clear std::vector<int>& gridDimension;

   /**
     * Set the PME grid dimensions.  If Ewald alpha is 0 (the default), this is ignored and grid dimensions
     * are chosen automatically based on the Ewald error tolerance.
     *
     * @param gridDimension   the PME grid dimensions
     * @deprecated This method exists only for backward compatibility.  Use setPMEParameters() instead.
     */
    void setPmeGridDimensions(const std::vector<int>& gridDimension);

    /**
     * Get the parameters being used for PME in a particular Context.  Because some platforms have restrictions
     * on the allowed grid sizes, the values that are actually used may be slightly different from those
     * specified with setPmeGridDimensions(), or the standard values calculated based on the Ewald error tolerance.
     * See the manual for details.
     *
     * @param context      the Context for which to get the parameters
     * @param[out] alpha   the separation parameter
     * @param[out] nx      the number of grid points along the X axis
     * @param[out] ny      the number of grid points along the Y axis
     * @param[out] nz      the number of grid points along the Z axis
     */
    %apply double& OUTPUT {double& alpha};
    %apply int& OUTPUT {int& nx};
    %apply int& OUTPUT {int& ny};
    %apply int& OUTPUT {int& nz};
    void getPMEParametersInContext(const Context& context, double& alpha, int& nx, int& ny, int& nz) const;
    %clear double& alpha;
    %clear int& nx;
    %clear int& ny;
    %clear int& nz;

    /**
     * Add multipole-related info for a particle
     *
     * @param charge               the particle's charge
     * @param molecularDipole      the particle's molecular dipole (vector of size 3)
     * @param molecularQuadrupole  the particle's molecular quadrupole (vector of size 9)
     * @param molecularOctopole    the particle's molecular octopole (vector of size 27)
     * @param axisType             the particle's axis type
     * @param multipoleAtomZ       index of first atom used in constructing lab<->molecular frames
     * @param multipoleAtomX       index of second atom used in constructing lab<->molecular frames
     * @param multipoleAtomY       index of second atom used in constructing lab<->molecular frames
     * @param thole                Thole parameter
     * @param alphas               A 3-vector containing the xx, yy and zz polarizabilities
     */
    int addMultipole(double charge, const std::vector<double>& molecularDipole, const std::vector<double>& molecularQuadrupole, const std::vector<double>& molecularOctopole,
                     int axisType, int multipoleAtomZ, int multipoleAtomX, int multipoleAtomY, double thole, const Vec3& alphas);

    /**
     * Get the multipole parameters for a particle.
     *
     * @param index                     the index of the atom for which to get parameters
     * @param[out] charge               the particle's charge
     * @param[out] molecularDipole      the particle's molecular dipole (vector of size 3)
     * @param[out] molecularQuadrupole  the particle's molecular quadrupole (vector of size 9)
     * @param[out] molecularOctopole    the particle's molecular octopole (vector of size 27)
     * @param[out] axisType             the particle's axis type
     * @param[out] multipoleAtomZ       index of first atom used in constructing lab<->molecular frames
     * @param[out] multipoleAtomX       index of second atom used in constructing lab<->molecular frames
     * @param[out] multipoleAtomY       index of second atom used in constructing lab<->molecular frames
     * @param[out] thole                Thole parameter
     * @param[out] alphas		   	    A 3-vector containing the xx, yy and zz polarizabilities
     */
    %apply double& OUTPUT {double& charge};
    %apply std::vector<double>& OUTPUT {std::vector<double>& molecularDipole};
    %apply std::vector<double>& OUTPUT {std::vector<double>& molecularQuadrupole};
    %apply std::vector<double>& OUTPUT {std::vector<double>& molecularOctopole};
    %apply int& OUTPUT {int& axisType};
    %apply int& OUTPUT {int& multipoleAtomZ};
    %apply int& OUTPUT {int& multipoleAtomX};
    %apply int& OUTPUT {int& multipoleAtomY};
    %apply double& OUTPUT {double& thole};
    %apply Vec3& OUTPUT {double& alphas};
    void getMultipoleParameters(int index, double& charge, std::vector<double>& molecularDipole, std::vector<double>& molecularQuadrupole, std::vector<double>& molecularOctopole,
                                int& axisType, int& multipoleAtomZ, int& multipoleAtomX, int& multipoleAtomY, double& thole, Vec3& alphas) const;
    %clear double& charge;
    %clear std::vector<double>& molecularDipole;
    %clear std::vector<double>& molecularQuadrupole;
    %clear std::vector<double>& molecularOctopole;
    %clear int& axisType;
    %clear int& multipoleAtomZ;
    %clear int& multipoleAtomX;
    %clear int& multipoleAtomY;
    %clear double& thole;
    %clear Vec3& alphas;

    /**
     * Set the multipole parameters for a particle.
     *
     * @param index                the index of the atom for which to set parameters
     * @param charge               the particle's charge
     * @param molecularDipole      the particle's molecular dipole (vector of size 3)
     * @param molecularQuadrupole  the particle's molecular quadrupole (vector of size 9)
     * @param molecularOctopole    the particle's molecular octopole (vector of size 27)
     * @param axisType             the particle's axis type
     * @param multipoleAtomZ       index of first atom used in constructing lab<->molecular frames
     * @param multipoleAtomX       index of second atom used in constructing lab<->molecular frames
     * @param multipoleAtomY       index of second atom used in constructing lab<->molecular frames
     * @param thole                thole parameter
     * @param alphas			   A 3-vector containing the xx, yy and zz polarizabilities
     */
    void setMultipoleParameters(int index, double charge, const std::vector<double>& molecularDipole, const std::vector<double>& molecularQuadrupole, const std::vector<double> &molecularOctopole,
                                int axisType, int multipoleAtomZ, int multipoleAtomX, int multipoleAtomY, double thole, const Vec3& alphas);

    /**
     * Set the CovalentMap for an atom
     *
     * @param index                the index of the atom for which to set parameters
     * @param typeId               CovalentTypes type
     * @param covalentAtoms        vector of covalent atoms associated w/ the specfied CovalentType
     */
    void setCovalentMap(int index, CovalentType typeId, const std::vector<int>& covalentAtoms);

    /**
     * Get the CovalentMap for an atom
     *
     * @param index                the index of the atom for which to set parameters
     * @param typeId               CovalentTypes type
     * @param[out] covalentAtoms   output vector of covalent atoms associated w/ the specfied CovalentType
     */
    %apply std::vector<int>& OUTPUT { std::vector<int>& covalentAtoms };
    void getCovalentMap(int index, CovalentType typeId, std::vector<int>& covalentAtoms) const;
    %clear std::vector<int>& covalentAtoms;

    /**
     * Get the CovalentMap for an atom
     *
     * @param index                the index of the atom for which to set parameters
     * @param[out] covalentLists   output vector of covalent lists of atoms
     */
    %apply std::vector<int>& OUTPUT { std::vector<int>& covalentLists };
    void getCovalentMaps(int index, std::vector < std::vector<int> >& covalentLists) const;
    %clear std::vector<int>& covalentLists;

    /**
     * Get the max number of iterations to be used in calculating the mutual induced dipoles
     *
     * @return max number of iterations
     */
    int getMutualInducedMaxIterations(void) const;

    /**
     * Set the max number of iterations to be used in calculating the mutual induced dipoles
     *
     * @param inputMutualInducedMaxIterations   number of iterations
     */
    void setMutualInducedMaxIterations(int inputMutualInducedMaxIterations);

    /**
     * Get the target epsilon to be used to test for convergence of iterative method used in calculating the mutual induced dipoles
     *
     * @return target epsilon
     */
    double getMutualInducedTargetEpsilon(void) const;

    /**
     * Set the target epsilon to be used to test for convergence of iterative method used in calculating the mutual induced dipoles
     *
     * @param inputMutualInducedTargetEpsilon   target epsilon
     */
    void setMutualInducedTargetEpsilon(double inputMutualInducedTargetEpsilon);

    /**
     * Set the coefficients for the mu_0, mu_1, mu_2, ..., mu_n terms in the extrapolation
     * algorithm for induced dipoles.
     *
     * @param coefficients      a vector whose mth entry specifies the coefficient for mu_m.  The length of this
     *                          vector determines how many iterations are performed.
     *
     */
    void setExtrapolationCoefficients(const std::vector<double> &coefficients);

    /**
     * Get the coefficients for the mu_0, mu_1, mu_2, ..., mu_n terms in the extrapolation
     * algorithm for induced dipoles.  In this release, the default values for the coefficients are
     * [-0.154, 0.017, 0.658, 0.474], but be aware that those may change in a future release.
     */
    const std::vector<double>& getExtrapolationCoefficients() const;

    /**
     * Get the error tolerance for Ewald summation.  This corresponds to the fractional error in the forces
     * which is acceptable.  This value is used to select the grid dimensions and separation (alpha)
     * parameter so that the average error level will be less than the tolerance.  There is not a
     * rigorous guarantee that all forces on all atoms will be less than the tolerance, however.
     *
     * This can be overridden by explicitly setting an alpha parameter and grid dimensions to use.
     */
    double getEwaldErrorTolerance() const;
    /**
     * Get the error tolerance for Ewald summation.  This corresponds to the fractional error in the forces
     * which is acceptable.  This value is used to select the grid dimensions and separation (alpha)
     * parameter so that the average error level will be less than the tolerance.  There is not a
     * rigorous guarantee that all forces on all atoms will be less than the tolerance, however.
     *
     * This can be overridden by explicitly setting an alpha parameter and grid dimensions to use.
     */
    void setEwaldErrorTolerance(double tol);
    /**
     * Get the fixed dipole moments of all particles in the global reference frame.
     *
     * @param context         the Context for which to get the fixed dipoles
     * @param[out] dipoles    the fixed dipole moment of particle i is stored into the i'th element
     */
    %apply std::vector<OpenMM::Vec3>& OUTPUT { std::vector<OpenMM::Vec3>& dipoles };
    void getLabFramePermanentDipoles(Context& context, std::vector<OpenMM::Vec3>& dipoles);
    %clear std::vector<OpenMM::Vec3>& dipoles;
    /**
     * Get the induced dipole moments of all particles.
     *
     * @param context         the Context for which to get the induced dipoles
     * @param[out] dipoles    the induced dipole moment of particle i is stored into the i'th element
     */
    %apply std::vector<OpenMM::Vec3>& OUTPUT { std::vector<OpenMM::Vec3>& dipoles };
    void getInducedDipoles(Context& context, std::vector<OpenMM::Vec3>& dipoles);
    %clear std::vector<OpenMM::Vec3>& dipoles;

    /**
     * Get the total dipole moments (fixed plus induced) of all particles.
     *
     * @param context         the Context for which to get the total dipoles
     * @param[out] dipoles    the total dipole moment of particle i is stored into the i'th element
     */
    %apply std::vector<OpenMM::Vec3>& OUTPUT { std::vector<OpenMM::Vec3>& dipoles };
    void getTotalDipoles(Context& context, std::vector<OpenMM::Vec3>& dipoles);
    %clear std::vector<OpenMM::Vec3>& dipoles;

    /**
     * Get the electrostatic potential.
     *
     * @param inputGrid    input grid points over which the potential is to be evaluated
     * @param context      context
     * @param[out] outputElectrostaticPotential output potential
     */
    %apply std::vector<double>& OUTPUT { std::vector<double>& outputElectrostaticPotential };
    void getElectrostaticPotential(const std::vector< OpenMM::Vec3 >& inputGrid,
                                    Context& context, std::vector< double >& outputElectrostaticPotential);
    %clear std::vector<double>& outputElectrostaticPotential;

    /**
     * Get the system multipole moments.
     *
     * This method is most useful for non-periodic systems.  When called for a periodic system, only the
     * <i>lowest nonvanishing moment</i> has a well defined value.  This means that if the system has a net
     * nonzero charge, the dipole and quadrupole moments are not well defined and should be ignored.  If the
     * net charge is zero, the dipole moment is well defined (and really represents a dipole density), but
     * the quadrupole moment is still undefined and should be ignored.
     *
     * @param context      context
     * @param[out] outputMultipoleMoments (charge,
                                           dipole_x, dipole_y, dipole_z,
                                           quadrupole_xx, quadrupole_xy, quadrupole_xz,
                                           quadrupole_yx, quadrupole_yy, quadrupole_yz,
                                           quadrupole_zx, quadrupole_zy, quadrupole_zz)
     */
    %apply std::vector<double>& OUTPUT { std::vector<double>& outputMultipoleMoments };
    void getSystemMultipoleMoments(Context& context, std::vector< double >& outputMultipoleMoments);
    %clear std::vector<double>& outputMultipoleMoments;
    /**
     * Update the multipole parameters in a Context to match those stored in this Force object.  This method
     * provides an efficient method to update certain parameters in an existing Context without needing to reinitialize it.
     * Simply call setMultipoleParameters() to modify this object's parameters, then call updateParametersInContext() to
     * copy them over to the Context.
     *
     * This method has several limitations.  The only information it updates is the parameters of multipoles.
     * All other aspects of the Force (the nonbonded method, the cutoff distance, etc.) are unaffected and can only be
     * changed by reinitializing the Context.  Furthermore, this method cannot be used to add new multipoles,
     * only to change the parameters of existing ones.
     */
    void updateParametersInContext(Context& context);
    /**
     * Returns whether or not this force makes use of periodic boundary
     * conditions.
     *
     * @returns true if nonbondedMethod uses PBC and false otherwise
     */
    bool usesPeriodicBoundaryConditions() const {
        return nonbondedMethod == MPIDForce::PME;
    }

    /**
     * Set the default Thole width (in nm) used for "direct" pairs.
     */
    void setDefaultTholeWidth();

    /**
     * Get the default Thole width (in nm) used for "direct" pairs.
     */
    double getDefaultTholeWidth() const;
};

}