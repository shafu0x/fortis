import Image from "next/image";
import { ChevronDown } from "lucide-react";
import { Input } from "../ui/input";
import { Button } from "../ui/button";
import { Label } from "../ui/label";

export default function TokenInput() {
  return (
    <div className="flex items-center justify-center  p-8">
      <div className="flex items-center gap-6 w-full max-w-2xl bg-gray-800 p-6 rounded-lg border border-gray-700">
        {/* Input Section */}
        <div className="flex-1">
          <Label
            htmlFor="amount"
            className="block text-sm font-medium text-gray-400 mb-2"
          >
            Enter Amount
          </Label>
          <Input
            id="amount"
            placeholder=""
            className="bg-gray-700 text-white placeholder-gray-400 border border-gray-600 focus:ring focus:ring-purple-500 focus:outline-none rounded-md px-4 py-2"
          />
          <Label className="block text-sm text-gray-400 mt-2">$1,221.44</Label>
        </div>

        {/* Max Button */}
        <Button className="bg-purple-600 text-white px-4 py-2 rounded-md">
          Max
        </Button>

        {/* Token Selector */}
        <div className="flex flex-col items-center gap-1 px-4 py-2 bg-gray-700 rounded-full border border-gray-600 hover:border-gray-500 cursor-pointer">
          <div className="flex items-center gap-2">
            <Image
              src="/images/tokens/usdc.png"
              width={24}
              height={24}
              alt="USDC"
              className="rounded-full"
            />
            <span className="text-white text-sm font-medium">USDC</span>
            <ChevronDown className="h-5 w-5 text-gray-400" />
          </div>
          <Label className="text-xs text-gray-400">1,221.44 USDC</Label>
        </div>
      </div>
    </div>
  );
}
