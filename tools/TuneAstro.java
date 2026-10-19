// Repair only annotations in an existing typed analysis project.
// @category AstroSquid
import ghidra.app.script.GhidraScript;
import ghidra.program.model.listing.*;
import ghidra.program.model.data.*;
import ghidra.program.model.symbol.*;

public class TuneAstro extends GhidraScript {
    public void run() throws Exception {
        for(long address:new long[]{0x10001e68L,0x100032ecL,0x1001b80cL}) {
            Function f=getFunctionAt(toAddr(address));
            if(f!=null) f.setInline(false);
        }
        Function f=getFunctionAt(toAddr(0x10001e68L));
        f.replaceParameters(Function.FunctionUpdateType.DYNAMIC_STORAGE_ALL_PARAMS,true,SourceType.USER_DEFINED,
            new ParameterImpl("preserved_r3",Undefined4DataType.dataType,currentProgram));
        f.setReturnType(Undefined4DataType.dataType,SourceType.USER_DEFINED);
        Structure entity=(Structure)currentProgram.getDataTypeManager().getDataType("/PPC_AstroEntity");
        if(entity!=null) {
            entity.replaceAtOffset(66,ShortDataType.dataType,2,"unknown_66",null);
            entity.replaceAtOffset(68,ShortDataType.dataType,2,"attribute_id",null);
            entity.replaceAtOffset(28,new ArrayDataType(ShortDataType.dataType,4,2),8,"previous_bounds",null);
            entity.replaceAtOffset(36,new ArrayDataType(ShortDataType.dataType,4,2),8,"bounds",null);
        }
    }
}
