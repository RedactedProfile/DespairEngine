# Despair Engine Model Exporter
import bpy
from dataclasses import dataclass

# The model format essentially apes off of a weird marriage between obj and md5
# in that the overall text file format is obj-like in style, purposely stupidly easy to parse 
# but the essential data flow follows md5's lead. Such as defining joints, weights and animation data
# There's some unique concessions of my own, like packing as much vertex data into one line as possible in the exact
# same format as I like to describe my vertex buffers, and only supporting triangles. 


@dataclass
class Vert:
    i: int      = 0
    vx: float   = 0.0
    vy: float   = 0.0
    vz: float   = 0.0
    nx: float   = 0.0
    ny: float   = 0.0
    nz: float   = 0.0
    u: float    = 0.0
    v: float    = 0.0
    r: float    = 0.0
    g: float    = 0.0
    b: float    = 0.0
    
    def __str__(self):
        return "v {} {} {} {} {} {} {} {} {} {} {} {}\n".format(
            self.i, 
            self.vx, 
            self.vy, 
            self.vz, 
            self.nx, 
            self.ny, 
            self.nz,
            self.u, 
            self.v, 
            self.r,
            self.g, 
            self.b
        )
    
@dataclass
class Joint:
    name: str
    parent: int = -1
    vx: float   = 0.0
    vy: float   = 0.0
    vz: float   = 0.0 
    rx: float   = 0.0
    ry: float   = 0.0
    rz: float   = 0.0

    def __str__(self):
        return "j {} {} {} {} {} {} {} {}\n".format(
            self.name,
            self.parent,
            self.vx,
            self.vy,
            self.vz,
            self.rx,
            self.ry,
            self.rz 
        )

@dataclass 
class Tri:
    i: int
    v1: int
    v2: int
    v3: int 

    def __str__(self):
        return "t {} {} {} {}\n".format(
            self.i,
            self.v1,
            self.v2,
            self.v3 
        )
    
@dataclass 
class Weight:
    i: int 
    j: int 
    w: float 
    x: float 
    y: float 
    z: float 

    def __str__(self):
        return "w {} {} {} {} {} {}\n".format(
            self.i,
            self.j,
            self.w,
            self.x,
            self.y,
            self.z 
        )



def write_some_data(context, filepath, use_some_setting):
    print("running writer...")
    f = open(filepath, 'w', encoding='utf-8')

    f.write("DEM_10\n")
    
    scene = bpy.context.scene 
    
    numMeshes = 0
    numJoints = 0
    for obj in scene.objects: 
        if obj.type == 'MESH':
            numMeshes+=1
        elif obj.type == 'JOINT':
            numJoints+=1
    
    
    f.write("joints {}\n".format(numJoints))
    for obj in scene.objects:
        if obj.type == 'JOINT':
            print("Discovered joint")
            # j jointName parentIndex vx vy vz rx ry rz 
    
    
    f.write("meshes {}\n".format(numMeshes))
    for obj in scene.objects:
        if obj.type == 'MESH':
            print("Discovered object %s" % obj.name)
            f.write("mesh %s\n" % obj.name)

            mesh = obj.data 
            uv_layer = mesh.uv_layers.active.data
#            color_layer = mesh.vertex_colors.active.data    # this was tripping errors
            
            if bpy.context.mode == 'EDIT_MESH':
                bpy.ops.object.mode_set(mode='OBJECT')
                
            f.write("s lightmapped_generic\n")
            
            f.write("verts {}\n".format(len(mesh.vertices)))
            VertArray = []
            for vertex in mesh.vertices:
                VertArray.append(Vert(
                    vertex.index, 
                    vertex.co.x, 
                    vertex.co.y, 
                    vertex.co.z, 
                    vertex.normal.x, 
                    vertex.normal.y, 
                    vertex.normal.z
                ))
            

            for poly in mesh.polygons:
                print(f"  Face {poly.index}:")

                for li in poly.loop_indices:
                    loop_idx = mesh.loops[li].vertex_index
                    loop = mesh.loops[li]
                    uv = uv_layer[li].uv
#                    color = color_layer[li].color
                    print(f"    Loop {li}: Vertex {loop.vertex_index} UV = {uv}")
#                    print(f"    Loop {li}: Vertex {loop.vertex_index} UV = {uv} Color = (R: {color[0]}, G: {color[1]}, B: {color[2]})")

            for vertex in VertArray:
                # v idx vx vy vz nx ny nz    (i'd like to include tu tv here as well)
                f.write(str(vertex))
                
                
            f.write("tris {}\n".format(0))
            # t idx vidx vidx vidx
            
            f.write("weights {}\n".format(0))
            # w idx jidx weight x y z
            
    
    
#    f.write("Hello World %s" % use_some_setting)
    f.close()

    return {'FINISHED'}


# ExportHelper is a helper class, defines filename and
# invoke() function which calls the file selector.
from bpy_extras.io_utils import ExportHelper
from bpy.props import StringProperty, BoolProperty, EnumProperty
from bpy.types import Operator


class ExportSomeData(Operator, ExportHelper):
    """This appears in the tooltip of the operator and in the generated docs"""
    bl_idname = "export_test.some_data"  # important since its how bpy.ops.import_test.some_data is constructed
    bl_label = "Export Some Data"

    # ExportHelper mixin class uses this
    filename_ext = ".dem"

    filter_glob: StringProperty(
        default="*.dem",
        options={'HIDDEN'},
        maxlen=255,  # Max internal buffer length, longer would be clamped.
    )

    # List of operator properties, the attributes will be assigned
    # to the class instance from the operator settings before calling.
    use_setting: BoolProperty(
        name="Example Boolean",
        description="Example Tooltip",
        default=True,
    )

    type: EnumProperty(
        name="Example Enum",
        description="Choose between two items",
        items=(
            ('OPT_A', "First Option", "Description one"),
            ('OPT_B', "Second Option", "Description two"),
        ),
        default='OPT_A',
    )

    def execute(self, context):
        return write_some_data(context, self.filepath, self.use_setting)


# Only needed if you want to add into a dynamic menu
def menu_func_export(self, context):
    self.layout.operator(ExportSomeData.bl_idname, text="Despair Engine Model (.dem)")


# Register and add to the "file selector" menu (required to use F3 search "Text Export Operator" for quick access).
def register():
    bpy.utils.register_class(ExportSomeData)
    bpy.types.TOPBAR_MT_file_export.append(menu_func_export)


def unregister():
    bpy.utils.unregister_class(ExportSomeData)
    bpy.types.TOPBAR_MT_file_export.remove(menu_func_export)


if __name__ == "__main__":
    register()

    # test call
    bpy.ops.export_test.some_data('INVOKE_DEFAULT')
