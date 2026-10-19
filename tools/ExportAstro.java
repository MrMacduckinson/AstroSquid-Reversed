// Export reproducible decompiler evidence, not a claimed buildable source tree.
// @category AstroSquid
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.*;
import ghidra.program.model.listing.*;
import ghidra.program.model.symbol.*;
import ghidra.program.model.mem.*;
import java.io.*;
import java.nio.charset.StandardCharsets;

public class ExportAstro extends GhidraScript {
    public void run() throws Exception {
        File root = new File(getScriptArgs()[0]);
        root.mkdirs();
        File code = new File(root, "pseudocode");
        code.mkdirs();
        DecompInterface decompiler = new DecompInterface();
        decompiler.openProgram(currentProgram);
        int done = 0, failed = 0;
        try (PrintWriter index = new PrintWriter(new File(root, "functions.tsv"), "UTF-8");
             PrintWriter symbols = new PrintWriter(new File(root, "symbols.tsv"), "UTF-8");
             PrintWriter calls = new PrintWriter(new File(root, "calls.tsv"), "UTF-8");
             PrintWriter blocks = new PrintWriter(new File(root, "blocks.tsv"), "UTF-8")) {
            index.println("address\tname\tbody_bytes\tdecompiled");
            symbols.println("address\ttype\tname");
            calls.println("function\tfrom\tto\tsymbol\ttype");
            for (MemoryBlock block : currentProgram.getMemory().getBlocks()) {
                blocks.println(block.getName()+"\t"+block.getStart()+"\t"+block.getSize());
                if (block.isInitialized()) {
                    try (OutputStream out = new FileOutputStream(new File(root, block.getName().replaceAll("[^a-zA-Z0-9_.-]", "_")+".bin"))) {
                        byte[] buffer = new byte[65536];
                        long left = block.getSize();
                        var address = block.getStart();
                        while (left > 0) {
                            int n = (int)Math.min(left, buffer.length);
                            currentProgram.getMemory().getBytes(address, buffer, 0, n);
                            out.write(buffer, 0, n); left -= n; address = address.add(n);
                        }
                    }
                }
            }
            for (Symbol symbol : currentProgram.getSymbolTable().getAllSymbols(true))
                symbols.println(symbol.getAddress()+"\t"+symbol.getSymbolType()+"\t"+symbol.getName(true));
            for (Function function : currentProgram.getFunctionManager().getFunctions(true)) {
                if (monitor.isCancelled()) break;
                DecompileResults result = decompiler.decompileFunction(function, 45, monitor);
                boolean ok = result.decompileCompleted() && result.getDecompiledFunction() != null;
                index.println(function.getEntryPoint()+"\t"+function.getName()+"\t"+function.getBody().getNumAddresses()+"\t"+ok);
                index.flush();
                File file = new File(code, function.getEntryPoint()+".c");
                try (PrintWriter writer = new PrintWriter(file, "UTF-8")) {
                    writer.println("/* Ghidra pseudocode. Original entry: "+function.getEntryPoint()+". Not yet reconstructed C. */");
                    writer.println(ok ? result.getDecompiledFunction().getC() : "/* "+result.getErrorMessage()+" */");
                }
                if (ok) done++; else failed++;
                for (Instruction instruction : currentProgram.getListing().getInstructions(function.getBody(), true)) {
                    for (Reference ref : instruction.getReferencesFrom()) {
                        Symbol target = currentProgram.getSymbolTable().getPrimarySymbol(ref.getToAddress());
                        if (ref.getReferenceType().isCall() || (target != null && !target.isDynamic()))
                            calls.println(function.getEntryPoint()+"\t"+ref.getFromAddress()+"\t"+ref.getToAddress()+"\t"+(target==null ? "" : target.getName(true))+"\t"+ref.getReferenceType());
                    }
                }
                if ((done+failed)%100 == 0) println("Exported "+done+" functions; failed "+failed);
            }
        }
        decompiler.dispose();
        println("ASTRO_EXPORT_COMPLETE decompiled="+done+" failed="+failed);
    }
}
