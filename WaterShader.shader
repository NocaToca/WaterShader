Shader "Unlit/WaterShader"
{
    Properties
    {
        //READ THE README IF YOU WANT TO UNDERSTAND THESE VARIABLES
        _Color ("Color", Color) = (0, 0, 1, 1)
        _BorderColor ("Border Color", Color) = (0, 0, 0, 1)
        _TimeScale ("Scrolling Speed", float) = 1
        _CellSize ("Cell Size", float) = 1
        _NoiseStrength ("Noise Strength", float) = 1
        _Alpha ("Alpha", Range(0, 1)) = .5
        _Modifier("Mod", float) = 2.5



        //_MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags {"Queue" = "Transparent" "RenderType" = "Transparent"}
        //LOD 100

        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            //Random Functions!
            //Needed for randomness
            float rand3dTo1d(float3 value, float3 dotDir = float3(12.9898, 78.233, 37.719)){
                //make value smaller to avoid artefacts
                float3 smallValue = sin(value);
                //get scalar value from 3d vector
                float random = dot(smallValue, dotDir);
                //make value more random by making it bigger and then taking the factional part
                random = frac(sin(random) * 143758.5453);
                return random;
            }

            
            //to 3d functions

            float3 rand3dTo3d(float3 value){
                return float3(
                    rand3dTo1d(value, float3(12.989, 78.233, 37.719)),
                    rand3dTo1d(value, float3(39.346, 11.135, 83.155)),
                    rand3dTo1d(value, float3(73.156, 52.235, 09.151))
                );
            }
            //Credit for these functions:
            //https://www.ronja-tutorials.com/2018/09/29/voronoi-noise.html
            //They make great tutorials, check them out!

            float _Modifier;

            //What we pull for the texture
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };

            //The interperlators (I know I didnt spell that right)
            float4 _Color;
            float4 _BorderColor;
            float _TimeScale;
            float _CellSize;
            float _NoiseStrength;
            float _Alpha;

            //This is the noise function that makes our little ripples 
            /* How it works is a bit complicated for me to explain, mostly because I still do not fully understand textures, but we basically map a bunch of cells on
            a 3D plane, then to smooth it out and make it not look as choppy we use the minimum distance to a cell to smooth out the noise, and return that as a float3
            since we're in a 3D plane*/
            float3 voronoiNoise(float3 value){
                float3 baseCell = floor(value);
                float minDistToCell = 10;
                [unroll]
                for(int x = -1; x <= 1; x++){
                    [unroll]
                    for(int y = -1; y <= 1; y++){
                        [unroll]
                        for(int z = -1; z <= 1; z++){
                            float3 cell = baseCell + float3(x, y, z);
                            float3 cellPosition = cell + rand3dTo3d(cell);
                            float3 toCell = cellPosition - value;
                            float distToCell = length(toCell);
                            if(distToCell < minDistToCell){
                                minDistToCell = distToCell;
                            
                            }
                        }
                    }
                }
                return minDistToCell;
            }


            //This is, quite obviously, the function setting the vertices of the mesh. 
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex) + (_Modifier / 100) * sin(_Time.y);
                o.normal = v.normal;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                
                return o;
            }

            //The fragment function actually outputs the color
            fixed4 frag (v2f i) : SV_Target
            {
                float4 col = _Color; //We can just use _Color but col is easier for me to type
                
                //First we get a value that's based on the world position and the cell size we want (we want to use world pos so the noise is consistent between pixels)
                float3 value = i.worldPos * _CellSize;
                value += _Time.y * _TimeScale; //This makes the noise scroll
                        
                //The noise pow function may look a bit confusing, but the baisc premise is that the noise is being changed by a sine wave so its not statically scrolling
                float3 noise = voronoiNoise(value);
                noise = pow(noise, 10 + 5 * sin((_Time.y * pow(_TimeScale, 2)) * .25));
                
                //And this basically just sets the noise to the color we want it to be
                float3 cellCol = float4(lerp(noise.xyz, col.xyz, .1), _Alpha);
                float3 color = lerp(cellCol, _BorderColor, _NoiseStrength);

                col *= float4(color, _Alpha);
                
                return col;
            }
            ENDCG
        }
    }
}
