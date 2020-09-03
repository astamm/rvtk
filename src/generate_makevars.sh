#! /bin/sh

# Generate the Makevars file

echo "PKG_CPPFLAGS = \$(CPPFLAGS) -Ivtk/include" > Makevars
#echo "PKG_LIBS = vtk/lib/libvtk.a" >> Makevars
echo "PKG_LIBS = -Lvtk/lib -lvtk" >> Makevars
echo "VTK_LIB = vtk/lib/libvtk.a" >> Makevars
echo "" >> Makevars
echo "PKG_CXXFLAGS = \$(CXX_VISIBILITY)" >> Makevars
echo "PKG_CFLAGS = \$(C_VISIBILITY)" >> Makevars
echo "" >> Makevars
echo "VTK_LIBS = `find vtk/lib -type f -name "*.o" -o -name "*.obj" | xargs`" >> Makevars
echo "" >> Makevars
echo ".PHONY: all" >> Makevars
echo "" >> Makevars
echo "all: \$(SHLIB)" >> Makevars
echo "" >> Makevars
echo "\$(SHLIB): \$(VTK_LIB)" >> Makevars
echo "" >> Makevars
echo "\$(VTK_LIB): \$(VTK_LIBS)" >> Makevars
echo "	\$(AR) rcs \$(VTK_LIB) \$(VTK_LIBS)" >> Makevars
echo "" >> Makevars
echo "clean:" >> Makevars
echo "	rm -f \$(VTK_LIBS) \$(SHLIB) \$(OBJECTS) \$(VTK_LIB)" >> Makevars
