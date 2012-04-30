
"""Basic PDB viewer

You can use your mouse and keyboard to control the camera. Press 'c'
to perform a camera drive."""

import math

import d3d11
import d3d11x
from d3d11c import *
from Scientific.IO.PDB import Structure


RED    =    (.5, 0, 0, 0)
GREEN  =    (0, .5, 0, 0)
BLUE   =    (0, 0, .5, 0)
YELLOW =    (.5, .5, 0, 0)
GRAY   =   (0.2,0.2,0.2, 0)
WHITE  =   (.5,.5,.5, 0)

ATOM_COLOR = {
    'C' :WHITE,
    'H' :WHITE,
    'O' :RED,
    'N' :BLUE,
    'S' :YELLOW,
}

def gets(s,p):
    m = re.search(p,s)
    if m:
        return m.group(1)

conf = Structure('pdb/2CD7.pdb')

class AtomSpec:
    
    CACHE = {}
    
    def getSize(symbol):
        pass
        
def key_search(D,key_list):
    for k in key_list:
        try:
            return D[k]
        except:
            pass
    return None
    
class AtomViewer(d3d11x.Frame):

    def setupResidues(self):
        # cache the bonds for performance.
        for i,residue in enumerate(conf.residues):
            
            self.residue = residue
            
            if residue.name in ['HOH','GOL']: continue
            
            C = residue.atoms['C']['position']

            self.bonds = []
            self.connect('H','N')
            self.connect('1H','N')
            self.connect('N','CA')
            self.connect('CA','C')
            self.connect('C','O')
            self.connect('CA','CB')
            self.connect('CB','CG')
            self.connect('CG','CD')
            self.connect('CD','CE')
            self.connect('CB','CG1') #val,ile
            self.connect('CB','CG2') #val,ile
            self.connect('CG','CD1') #leu,phe,tyr,trp
            self.connect('CG','CD2') #leu,phe,tyr,trp,his
            self.connect('CG1','CD') #ile
            self.connect('CG1','CD1') #ile
            self.connect('CE','NZ') #lys
            self.connect('CG','OD1') #asp
            self.connect('CG','OD2') #asp
            self.connect('CD','OE1') #glu
            self.connect('CD','OE2') #glu
            self.connect('CG','OD') #asn,arg
            self.connect('CG','ND') #asn,arg
            self.connect('CD','OE') #gln
            self.connect('CD','NE') #gln
            self.connect('CB','SG') #cys
            self.connect('CB','OG') #ser,thr
            self.connect('ND','NE1') #arg
            self.connect('ND','NE2') #arg
            self.connect('CG','SD') #met
            self.connect('SD','CE') #met
            self.connect('SD','CE') #met
            self.connect('CD1','CE1') #phe,tyr
            self.connect('CD2','CE2') #phe,tyr,trp
            self.connect('CE1','CZ') #phe,tyr
            self.connect('CE2','CZ') #phe,tyr
            self.connect('CZ','OH') #tyr
            self.connect('CD1','NE1') #trp
            self.connect('NE1','CE2') #trp
            self.connect('CD2','CE3') #trp
            self.connect('CE3','CZ3') #trp
            self.connect('CE2','CZ2') #trp
            self.connect('CZ2','CH') #trp
            self.connect('CZ3','CH') #trp
            self.connect('CG','ND1') #his
            self.connect('ND1','CE1') #his
            self.connect('CE1','NE2') #his
            self.connect('NE2','CD2') #his
           
            if residue.name == 'PRO':
                self.connect('CD','N') #pro
            
            #Kyra's connections:
            self.connect('','')
            self.connect('','')
            self.connect('','')
            self.connect('','')
            self.connect('','')

            carbons = [a for a in self.residue.atoms.keys() if 'C' in a]
            #print carbons
            if C:
                carbons.remove('C')
            for carbon in carbons:
                code = carbon[1:]
                self.connect('H%s'%code,carbon)
                self.connect('1H%s'%code,carbon)
                self.connect('2H%s'%code,carbon)
                self.connect('3H%s'%code,carbon)
            
            if i < len(conf.residues) - 1:
                N_next = conf.residues[i+1].atoms['N']['position']
                if C:
                    self.bonds += [
                        (C[0],C[1],C[2],3.0,0xff00ff00)
                    ]
                if N_next:
                    self.bonds += [
                        (N_next[0],N_next[1],N_next[2],3.0,0xff00ff00),
                    ]
                
            residue[0].properties['bonds_cache']=self.bonds
            
            for atom in residue:
                pass
                # TODO: cache atom render specs for performance.
                
                
    def connect(self, atom1k, atom2k):
        if self.residue.atoms.has_key(atom1k) and self.residue.atoms.has_key(atom2k):
            #print 'connecting', atom1k, atom2k
            A1 = self.residue.atoms[atom1k]['position']
            A2 = self.residue.atoms[atom2k]['position']
            self.bonds = self.bonds + [
                (A1[0],A1[1],A1[2],3.0,0xff00ff00),
                (A2[0],A2[1],A2[2],3.0,0xff00ff00),
            ]
                
                
    def onCreate(self):
        
        #Sphere mesh.
        meshPath = d3d11x.getResourceDir("Mesh", "sphere.obj")
        self.sphere = d3d11x.Mesh(self.device, meshPath)
        self.sphere.textureView = self.loadTextureView("misc-white.bmp")
        
        #User controlled camera.
        self.camera = d3d11x.Camera((0, 0, -40), (0, 1, 0), 1.0)
                
    def onMessage(self, msg):
        if self.camera.onMessage(msg):
            return True
            
    def onUpdate(self):
        self.camera.onUpdate(self.frameTime)

    def onChar(self, msg):
        if msg.char == "c":
            self.camera.drive((-60, 30, 60), (0, 0, 0))
        
    def onRender(self):
        lights = [
          (d3d11.Vector(35,35,35),(1,1,1,1)),
          (d3d11.Vector(-35,25,25),(2,2,2,1)),
          (d3d11.Vector(25,-35,25),(2,2,2,1)),
        ]
        view = self.camera.getViewMatrix() 
        projection = self.createProjection(60, 0.1, 500.0)
    
        atoms = self.createAtoms()
     
        self.sphere.setLights(lights)
        
        for atom in atoms:
            #World matrix.
            meshWorld = d3d11.Matrix()
            atomPos = atom[0]
            #Add little to y to lift the sphere off the ground.
            meshWorld.translate((atomPos.x, atomPos.y + 1, atomPos.z))

            self.sphere.effect.set("lightAmbient", atom[1])
            self.sphere.render(meshWorld, view, projection)
            
    def createAtoms(self):
      atoms = []
      for i,residue in enumerate(conf.residues):
         for k,atom in residue.atoms.items():
            x,y,z = atom['position']
            pos = d3d11.Vector(x, y + 1,  z)
            color = ATOM_COLOR[atom.properties['element']]
            atoms.append((pos, color))
      return atoms
        

if __name__ == "__main__":
    a = AtomViewer("Glutamate - DirectPython 11", __doc__)
    a.mainloop()
