// Give the analysis copy its known FutureBASIC register conventions and literals.
// @category AstroSquid
import ghidra.app.script.GhidraScript;
import ghidra.program.model.listing.*;
import ghidra.program.model.mem.*;
import ghidra.program.model.symbol.*;
import ghidra.program.model.data.*;
import java.io.*;
import java.math.BigInteger;

public class PrepareAstro extends GhidraScript {
    public void run() throws Exception {
        byte[] literals = java.nio.file.Files.readAllBytes(new File(getScriptArgs()[0]).toPath());
        var memory = currentProgram.getMemory();
        var globals = toAddr(0x20000000L);
        memory.createInitializedBlock("FBGlobalsBeforeLiterals", globals, 0x21c, (byte)0, monitor, false);
        var pointer = memory.createInitializedBlock("FBLiteralPointer", globals.add(0x21c), 4, (byte)0, monitor, false);
        memory.setInt(globals.add(0x21c), 0x21000000);
        pointer.setWrite(false);
        memory.createInitializedBlock("FBGlobalsAfterLiterals", globals.add(0x220), 0x120e-0x220, (byte)0, monitor, false);
        var lit = memory.createInitializedBlock("FBLiterals", toAddr(0x21000000L), new ByteArrayInputStream(literals), literals.length, monitor, false);
        lit.setWrite(false);
        var text = memory.getBlock("Code");
        currentProgram.getProgramContext().setValue(currentProgram.getRegister("r14"), text.getStart(), text.getEnd(), BigInteger.valueOf(0x20000000L));
        long[] inline = {0xc2c,0xc60,0xc98,0xccc,0xd00,0xd38,0xda8,0xd70,0xde8,
                         0xe34,0xe9c,0xed4,0xf0c,0xf44,0x103c,0x10d8,0x10a8,
                         0x1164,0x11b4,0x1384,0x13e4};
        for (long offset : inline) {
            var at = toAddr(0x10000000L+offset);
            disassemble(at);
            Function f = getFunctionAt(at);
            if (f == null) f = createFunction(at, "FB_"+Long.toHexString(offset));
            if (f != null) f.setInline(true);
        }
        String[][] names = {
            {"1003d844","Astro_CheckRegistration"},
            {"1003dda8","Astro_LoadPreferences"},
            {"1003dee8","Astro_SavePreferences"},
            {"1003f178","Astro_MenuAction"},
            {"100353e4","LM_LoadScene"},
            {"100510c8","Astro_LoadLevel"},
            {"10066ce4","Astro_MainLoop"},
            {"10046394","Astro_DrawMenu"},
            {"10064154","Astro_InitMenu"}
        };
        for (String[] entry : names) {
            Function f = getFunctionAt(toAddr(entry[0]));
            if (f != null) f.setName(entry[1],SourceType.USER_DEFINED);
        }
        if (getScriptArgs().length > 1) {
            int renamed = 0;
            for (String line : java.nio.file.Files.readAllLines(new File(getScriptArgs()[1]).toPath())) {
                String[] parts = line.split("\t");
                if (parts.length < 2) continue;
                Function f = getFunctionAt(toAddr(parts[0]));
                if (parts.length > 2) {
                    Function best = null;
                    var candidates = currentProgram.getFunctionManager().getFunctions(toAddr(parts[0]),true);
                    while (candidates.hasNext()) {
                        Function candidate = candidates.next();
                        if (candidate.getEntryPoint().compareTo(toAddr(parts[2])) >= 0) break;
                        if (!candidate.isThunk() && (best == null || candidate.getBody().getNumAddresses() > best.getBody().getNumAddresses())) best=candidate;
                    }
                    if (best != null) f=best;
                }
                if (f == null) continue;
                String name = parts[1].replaceAll("[^A-Za-z0-9_]", "_");
                try { f.setName(name,SourceType.USER_DEFINED); renamed++; }
                catch (Exception e) { println("Name retained for "+parts[0]+": "+e.getMessage()); }
            }
            println("Original FutureBASIC names assigned: "+renamed);
        }
        Function bounds = getFunctionAt(toAddr(0x1001b80cL));
        if (bounds != null) bounds.setName("FB_ArrayIndexChecked",SourceType.USER_DEFINED);
        Function clear = getFunctionAt(toAddr(0x10001e68L));
        if (clear != null) {
            // R3 is preserved by this nonstandard ABI helper. Its actual local
            // clears still need explicit translation; do not make it a no-op.
            clear.replaceParameters(Function.FunctionUpdateType.DYNAMIC_STORAGE_ALL_PARAMS,true,SourceType.USER_DEFINED,
                new ParameterImpl("preserved_r3",Undefined4DataType.dataType,currentProgram));
            clear.setReturnType(Undefined4DataType.dataType,SourceType.USER_DEFINED);
        }
        Structure entity = new StructureDataType("PPC_AstroEntity",106);
        int[] shortOffsets={0,2,4,20,22,24,26,60,66,68,70,88,90,96};
        String[] shortNames={"kind","subtype","state","script_id","script_line","frame","tilt",
            "base_frame","unknown_66","attribute_id","remove_flag","hit_points","layer","tag"};
        for (int i=0;i<shortOffsets.length;i++) entity.replaceAtOffset(shortOffsets[i],ShortDataType.dataType,2,shortNames[i],null);
        int[] doubles={44,52,72,80}; String[] doubleNames={"x","y","vx","vy"};
        for (int i=0;i<doubles.length;i++) entity.replaceAtOffset(doubles[i],DoubleDataType.dataType,8,doubleNames[i],null);
        entity.replaceAtOffset(8,IntegerDataType.dataType,4,"update_tick",null);
        entity.replaceAtOffset(12,IntegerDataType.dataType,4,"animation_tick",null);
        entity.replaceAtOffset(16,IntegerDataType.dataType,4,"action_tick",null);
        entity.replaceAtOffset(28,new ArrayDataType(ShortDataType.dataType,4,2),8,"previous_bounds",null);
        entity.replaceAtOffset(36,new ArrayDataType(ShortDataType.dataType,4,2),8,"bounds",null);
        entity.replaceAtOffset(62,new PointerDataType(VoidDataType.dataType,4),4,"render_sprite",null);
        entity.replaceAtOffset(92,new PointerDataType(entity,4),4,"parent",null);
        entity.replaceAtOffset(98,new PointerDataType(entity,4),4,"previous",null);
        entity.replaceAtOffset(102,new PointerDataType(entity,4),4,"next",null);
        entity = (Structure)currentProgram.getDataTypeManager().addDataType(entity,DataTypeConflictHandler.REPLACE_HANDLER);
        DataType entityPtr=new PointerDataType(entity,4);
        long[] singleArgument={0x100528b4L,0x10052a94L,0x100549e8L,0x1005e994L,0x1005ed70L,0x10061a48L,0x10061c40L,0x100636a0L};
        for(long address:singleArgument) {
            Function f=getFunctionAt(toAddr(address));
            if(f!=null) f.replaceParameters(Function.FunctionUpdateType.DYNAMIC_STORAGE_ALL_PARAMS,true,SourceType.USER_DEFINED,
                new ParameterImpl("entity",entityPtr,currentProgram));
        }
        long[] globalPointers={0x20000a76L,0x20000a7aL}; String[] globalNames={"g_entities","g_player"};
        for(int i=0;i<globalPointers.length;i++) {
            DataUtilities.createData(currentProgram,toAddr(globalPointers[i]),entityPtr,-1,false,DataUtilities.ClearDataMode.CLEAR_ALL_CONFLICT_DATA);
            createLabel(toAddr(globalPointers[i]),globalNames[i],true);
        }
        Function push = getFunctionAt(toAddr(0x10003220L));
        if (push != null) {
            var result = new ReturnParameterImpl(new PointerDataType(DoubleDataType.dataType),
                new VariableStorage(currentProgram,currentProgram.getRegister("r3")),currentProgram);
            var value = new ParameterImpl("value",DoubleDataType.dataType,
                new VariableStorage(currentProgram,currentProgram.getRegister("f14")),currentProgram);
            push.updateFunction(push.getCallingConventionName(),result,
                Function.FunctionUpdateType.CUSTOM_STORAGE,true,SourceType.USER_DEFINED,value);
        }
        println("Astro register and literal annotations applied to analysis copy only");
    }
}
