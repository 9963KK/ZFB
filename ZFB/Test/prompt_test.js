// 使用全局变量
const ingredients = window.ingredients || [];
const meals = window.meals || [];
const API_CONFIG = window.API_CONFIG || {};
const API_KEYS = window.API_KEYS || {};

// 添加调试信息
console.log('配置加载状态:', { API_CONFIG, API_KEYS });
console.log('全局变量状态:', { ingredients, meals });

// 定义食谱类型
const RECIPE_TYPES = {
    all: '全部类型',
    quick: '快手菜',
    nutritious: '营养大餐',
    onepot: '省时锅'
};

// 定义整数单位列表
const integerUnits = ["个", "颗", "把", "包", "只", "条"];

// API配置
const config = {
    apiKey: 'sk-78cace0809a442c1a526392235df3e75',
    baseURL: 'dashscope.aliyuncs.com/compatible-mode/v1',
    model: 'qwen-max',
    temperature: 0.6,
    timeout: 60000,  // 超时时间改为60秒
    maxRetries: 3,   // 最大重试次数
    retryDelay: 2000 // 重试延迟时间(ms)
};

// 数据处理相关函数
function updateQuantityInput() {
    const unit = document.getElementById('unit').value;
    const quantityInput = document.getElementById('quantity');
    
    if (integerUnits.includes(unit)) {
        quantityInput.step = "1";
        quantityInput.value = Math.round(parseFloat(quantityInput.value || 1));
    } else {
        quantityInput.step = "0.1";
    }
}

function formatQuantity(value, unit) {
    if (integerUnits.includes(unit)) {
        return Math.round(value).toString();
    } else {
        return parseFloat(value).toFixed(1);
    }
}

// 食材管理相关函数
function addIngredient() {
    const name = document.getElementById('name').value;
    const category = document.getElementById('category').value;
    const unit = document.getElementById('unit').value;
    let quantity = document.getElementById('quantity').value;
    const purchaseDate = document.getElementById('purchaseDate').value;
    const expiryDate = document.getElementById('expiryDate').value;

    if (!name) return;

    // 根据单位类型处理数量
    if (integerUnits.includes(unit)) {
        quantity = Math.round(parseFloat(quantity));
    } else {
        quantity = parseFloat(quantity);
    }

    ingredients.push({
        id: Date.now(),
        name,
        category,
        quantity,
        unit,
        purchaseDate: purchaseDate ? new Date(purchaseDate) : new Date(),
        expiryDate: expiryDate ? new Date(expiryDate) : null
    });

    updateIngredientList();
    clearIngredientForm();
}

function removeIngredient(id) {
    ingredients = ingredients.filter(item => item.id !== id);
    updateIngredientList();
}

function updateIngredientList() {
    const list = document.getElementById('ingredientList');
    list.innerHTML = ingredients.map(item => {
        const purchaseDays = Math.floor((new Date() - new Date(item.purchaseDate)) / (1000 * 60 * 60 * 24));
        const purchaseInfo = purchaseDays === 0 ? "今天购买" : `已购买${purchaseDays}天`;
        const expiryInfo = item.expiryDate ? formatExpiryDate(item.expiryDate) : "无过期日期";
        
        const displayQuantity = formatQuantity(item.quantity, item.unit);
        
        return `
            <div class="ingredient-item" data-id="${item.id}">
                <span>${item.name} (${displayQuantity}${item.unit}) - ${item.category}</span>
                <span style="font-size: 12px; color: #666;">${purchaseInfo} | ${expiryInfo}</span>
                <button class="remove-btn">×</button>
            </div>
        `;
    }).join('');
}

function clearIngredientForm() {
    document.getElementById('name').value = '';
    document.getElementById('quantity').value = '1';
    document.getElementById('purchaseDate').value = '';
    document.getElementById('expiryDate').value = '';
}

// 饮食记录相关函数
function addMeal() {
    const mealName = document.getElementById('mealName').value;
    if (!mealName) return;

    meals.push(mealName);
    updateMealHistory();
    document.getElementById('mealName').value = '';
}

function removeMeal(index) {
    meals.splice(index, 1);
    updateMealHistory();
}

function updateMealHistory() {
    const history = document.getElementById('mealHistory');
    history.innerHTML = meals.map((meal, index) => `
        <div class="ingredient-item" data-index="${index}">
            <span>${meal}</span>
            <button class="remove-btn">×</button>
        </div>
    `).join('');
}

// 日期处理相关函数
function formatDate(date) {
    const formatter = new Intl.DateTimeFormat('zh-CN', { month: 'numeric', day: 'numeric' });
    return formatter.format(date);
}

function isNearExpiry(date) {
    if (!date) return false;
    const days = Math.ceil((new Date(date) - new Date()) / (1000 * 60 * 60 * 24));
    return days <= 3 && days >= 0;
}

function formatExpiryDate(date) {
    if (!date) return "无保质期";
    const days = Math.ceil((new Date(date) - new Date()) / (1000 * 60 * 60 * 24));
    return `${days}天`;
}

// Prompt 生成和处理相关函数
function generatePrompt() {
    // 获取选中的食谱类型
    const selectedType = document.querySelector('input[name="recipeType"]:checked').value;
    
    // 构建食谱类型和数量
    let type, amount;
    if (selectedType === 'all') {
        type = "快手菜、营养大餐、省时锅";
        amount = 2;
    } else {
        type = RECIPE_TYPES[selectedType];
        amount = 3;
    }

    // 构建历史记录对象
    const history = {};
    meals.forEach((meal, index) => {
        const date = new Date();
        date.setDate(date.getDate() - index);
        history[formatDate(date)] = meal;
    });

    // 构建食材库存对象
    const store = {};
    ingredients.forEach(item => {
        if (!store[item.category]) {
            store[item.category] = {};
        }
        store[item.category][item.name] = {
            amount: `${item.quantity}${item.unit}`,
            days_left: item.expiryDate ? formatExpiryDate(item.expiryDate) : "无过期日期"
        };
    });

    // 构建 JSON 格式的 prompt
    const promptData = {
        Requirements: `请严格按照以下要求生成食谱：
1. 基本要求：
   - 优先使用临近过期食材（剩余保质期<3天）
   - 确保营养均衡（蛋白质占比20-35%）
   - 避免重复最近6天的食谱
2. 输出格式：
   - 必须严格按照 JSON_EXAMPLE 的格式输出
   - 保持完全相同的字段名称和数据类型
   - 遵循示例中的数据结构和嵌套关系
   - 确保生成的 JSON 可以被正确解析`,
        Type: type,
        Amount: amount,
        History: history,
        Store: store,
        JSON_REQUIREMENTS: `1. 食材用量规则：
   - 所有食材必须标注具体数量，禁止使用"适量"、"少许"等模糊词
   - 主料用量需符合份量要求（如4人份）
   - 调味料需标注具体克数或毫升数
   - 遵循常见用量习惯（如：盐1-2克，酱油5-10毫升）
   - 特殊调味料也需标注具体用量（如：八角1个，花椒2克）

2. 字段格式要求：
   - name: 字符串，菜品名称（如"红烧排骨"）
   - type: 字符串，必须是"快手菜"、"营养大餐"或"省时锅"之一
   - cooking_time: 字符串，格式为"数字+分钟"（如"45分钟"）
   - servings: 字符串，格式为"数字+人份"（如"4人份"）
   - calories: 整数，每份卡路里含量
   - nutrition: 对象，包含三个整数字段：
     * protein: 蛋白质占比（20-35之间）
     * carb: 碳水占比
     * fat: 脂肪占比
     * 三项占比之和必须等于100
   - ingredients: 数组，每个元素包含：
     * name: 字符串，食材名称
     * amount: 数字，食材用量
     * unit: 字符串，计量单位
   - steps: 字符串数组，每个步骤必须详细具体
   - expiration_priority: 布尔值，是否优先使用临期食材
   - tips: 字符串，包含具体的烹饪建议和技巧

3. 数据验证要求：
   - 所有必填字段不能为空
   - 数值字段不能为负数
   - 数组至少包含一个元素
   - 字符串不能为空字符串
   - 布尔值必须明确指定`,
        JSON_EXAMPLE: {
            recipes: [
                {
                    name: "红烧排骨",  // 示例：一道具体的菜品
                    type: "营养大餐",
                    cooking_time: "45分钟",
                    servings: "4人份",
                    calories: 650,
                    nutrition: {
                        protein: 35,  // 蛋白质
                        carb: 40,     // 碳水
                        fat: 25       // 脂肪
                    },
                    ingredients: [
                        {
                            name: "排骨",
                            amount: 500,
                            unit: "克"
                        },
                        {
                            name: "生抽",
                            amount: 15,
                            unit: "毫升"
                        },
                        {
                            name: "老抽",
                            amount: 5,
                            unit: "毫升"
                        },
                        {
                            name: "料酒",
                            amount: 10,
                            unit: "毫升"
                        },
                        {
                            name: "盐",
                            amount: 2,
                            unit: "克"
                        }
                    ],
                    steps: [
                        "排骨切段，冷水下锅焯烫去血水",
                        "锅中放油，爆香姜片和葱段",
                        "加入排骨翻炒上色",
                        "加入生抽、老抽、料酒调味",
                        "加入适量热水，大火烧开后转小火炖煮30分钟",
                        "调入盐和糖，收汁即可"
                    ],
                    expiration_priority: true,
                    tips: "1. 焯水时加入几片姜片去腥 2. 炖煮时间要足够长，确保排骨软烂"
                }
            ]
        }
    };

    // 将对象转换为格式化的 JSON 字符串
    document.getElementById('promptResult').textContent = JSON.stringify(promptData, null, 2);
}

function copyPrompt() {
    const prompt = document.getElementById('promptResult').textContent;
    navigator.clipboard.writeText(prompt).then(() => {
        alert('Prompt 已复制到剪贴板！');
    });
}

// AI 响应处理相关函数
function parseAIResponse() {
    const responseText = document.getElementById('aiResponse').value;
    try {
        // 打印原始响应用于调试
        console.log('原始响应:', responseText);
        
        // 尝试从回复中提取 JSON 部分
        let jsonMatch = responseText.match(/\{[\s\S]*\}/);
        if (!jsonMatch) {
            throw new Error('未找到有效的 JSON 数据');
        }
        
        let jsonStr = jsonMatch[0];
        
        // 预处理 JSON 字符串
        jsonStr = jsonStr
            // 移除 BOM 和其他不可见字符
            .replace(/^\uFEFF/, '')
            .replace(/[\u0000-\u0019]+/g, " ")
            // 处理中文引号
            .replace(/[""]/g, '"')
            .replace(/['']/g, "'")
            // 处理多余的逗号
            .replace(/,(\s*[}\]])/g, "$1")
            .replace(/,\s*,/g, ",")
            // 处理错误的转义
            .replace(/([^\\])\\/g, "$1\\\\")
            .replace(/\\([^"\\\/bfnrtu])/g, "\\\\$1")
            // 处理未闭合的数组和对象
            .replace(/\[([^\]]*)$/, "[$1]")
            .replace(/\{([^\}]*)$/, "{$1}")
            // 处理错误的 Unicode 转义
            .replace(/\\u([0-9a-fA-F]{0,4})/g, (match, p1) => {
                return p1.length === 4 ? match : `\\\\u${p1}`;
            })
            // 处理特殊字符
            .replace(/[\n\r\t]/g, " ")
            // 处理多余的空格
            .replace(/"\s+([^"]*)\s+"/g, '"$1"')
            .trim();

        // 在解析前打印处理后的 JSON 字符串
        console.log('预处理后的 JSON:', jsonStr);
        
        // 尝试分段解析，找出具体的错误位置
        try {
            const data = JSON.parse(jsonStr);
            
            if (!data.recipes || !Array.isArray(data.recipes)) {
                throw new Error('数据格式不正确：缺少 recipes 数组');
            }
            
            const recipes = data.recipes;
            
            // 显示解析后的食谱
            const parsedResponse = document.getElementById('parsedResponse');
            parsedResponse.innerHTML = recipes.map(recipe => `
                <div class="recipe-card">
                    <div class="recipe-title">${recipe.name || '未命名食谱'}</div>
                    <div class="recipe-info">
                        <span>类型: ${recipe.type || '未指定'}</span>
                        <span>烹饪时间: ${recipe.cooking_time || '未指定'}</span>
                        <span>份量: ${recipe.servings || '未指定'}</span>
                        <span>热量: ${recipe.calories || '未指定'}卡路里</span>
                        <div style="margin-top: 8px;">
                            <span>营养成分：</span>
                            <span>蛋白质: ${recipe.nutrition?.protein || 0}%</span>
                            <span>碳水: ${recipe.nutrition?.carb || 0}%</span>
                            <span>脂肪: ${recipe.nutrition?.fat || 0}%</span>
                        </div>
                        ${recipe.expiration_priority ? '<span style="color: #ff3b30">⚠️ 优先制作</span>' : ''}
                    </div>
                    <div class="recipe-ingredients">
                        <strong>食材:</strong>
                        <ul>
                            ${(recipe.ingredients || []).map(ing => 
                                `<li>${ing.name || ''} ${ing.amount || 0}${ing.unit || ''}</li>`
                            ).join('')}
                        </ul>
                    </div>
                    <div class="recipe-steps">
                        <strong>步骤:</strong>
                        <ol>
                            ${(recipe.steps || []).map(step => `<li>${step}</li>`).join('')}
                        </ol>
                    </div>
                    ${recipe.tips ? `
                    <div class="recipe-tips">
                        <strong>烹饪建议：</strong>
                        <p>${recipe.tips}</p>
                    </div>
                    ` : ''}
                </div>
            `).join('');
        } catch (parseError) {
            // 如果解析失败，尝试定位错误位置
            const errorPosition = parseError.message.match(/position (\d+)/);
            let errorContext = '';
            if (errorPosition && errorPosition[1]) {
                const pos = parseInt(errorPosition[1]);
                const start = Math.max(0, pos - 50);
                const end = Math.min(jsonStr.length, pos + 50);
                errorContext = `
                    <div style="margin-top: 10px;">
                        <strong>错误位置上下文：</strong>
                        <pre style="background: #fff; padding: 8px; border-radius: 4px; overflow-x: auto;">
                            ...${jsonStr.substring(start, pos)}<span style="color: red; font-weight: bold">${jsonStr.charAt(pos)}</span>${jsonStr.substring(pos + 1, end)}...
                        </pre>
                    </div>
                `;
            }
            
            // 显示详细的错误信息
            const parsedResponse = document.getElementById('parsedResponse');
            parsedResponse.innerHTML = `
                <div style="color: #ff3b30; padding: 16px; background: #fff3f3; border-radius: 8px;">
                    <h3>JSON 解析错误</h3>
                    <p>${parseError.message}</p>
                    <p>请检查 AI 回复格式是否符合要求。</p>
                    ${errorContext}
                    <div style="margin-top: 12px;">
                        <strong>调试信息：</strong>
                        <pre style="background: #fff; padding: 8px; border-radius: 4px; overflow-x: auto;">${parseError.stack}</pre>
                    </div>
                </div>
            `;
            throw parseError;
        }
    } catch (error) {
        console.error('解析错误:', error);
        console.log('原始响应:', responseText);
        
        // 如果还没有显示错误信息（可能是在预处理阶段出错）
        if (!document.getElementById('parsedResponse').innerHTML.includes('JSON 解析错误')) {
            const parsedResponse = document.getElementById('parsedResponse');
            parsedResponse.innerHTML = `
                <div style="color: #ff3b30; padding: 16px; background: #fff3f3; border-radius: 8px;">
                    <h3>预处理错误</h3>
                    <p>${error.message}</p>
                    <p>请检查 AI 回复格式是否符合要求。</p>
                    <div style="margin-top: 12px;">
                        <strong>调试信息：</strong>
                        <pre style="background: #fff; padding: 8px; border-radius: 4px; overflow-x: auto;">${error.stack}</pre>
                    </div>
                </div>
            `;
        }
    }
}

async function callOpenAI() {
    const model = document.getElementById('modelSelect').value;
    const loadingIndicator = document.getElementById('loadingIndicator');
    const aiResponse = document.getElementById('aiResponse');
    const prompt = document.getElementById('promptResult').textContent;

    let retryCount = 0;
    const startTime = Date.now();
    let timerInterval;
    
    loadingIndicator.style.display = 'block';
    loadingIndicator.innerHTML = '<p>正在发送请求...<br>已用时：0秒</p>';
    aiResponse.value = '';

    // 启动计时器
    timerInterval = setInterval(() => {
        const elapsedSeconds = Math.floor((Date.now() - startTime) / 1000);
        const minutes = Math.floor(elapsedSeconds / 60);
        const seconds = elapsedSeconds % 60;
        const timeText = minutes > 0 ? 
            `${minutes}分${seconds}秒` : 
            `${seconds}秒`;
        loadingIndicator.innerHTML = `<p>${loadingIndicator.innerHTML.split('<br>')[0]}<br>已用时：${timeText}</p>`;
    }, 1000);

    while (retryCount <= config.maxRetries) {
        try {
            const controller = new AbortController();
            const timeoutId = setTimeout(() => controller.abort(), config.timeout);

            const response = await fetch(`${API_CONFIG.baseURL}/chat/completions`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${getApiKey()}`
                },
                body: JSON.stringify({
                    model: model,
                    messages: [{
                        role: 'user',
                        content: prompt
                    }],
                    temperature: API_CONFIG.temperature
                }),
                signal: controller.signal
            });

            clearTimeout(timeoutId);

            if (!response.ok) {
                throw new Error(`API 请求失败: ${response.status}`);
            }

            loadingIndicator.innerHTML = `<p>正在处理 AI 响应...<br>已用时：${Math.floor((Date.now() - startTime) / 1000)}秒</p>`;
            const data = await response.json();
            const aiReply = data.choices[0].message.content;
            aiResponse.value = aiReply;

            // 计算总耗时
            const totalTime = Date.now() - startTime;
            const totalMinutes = Math.floor(totalTime / (1000 * 60));
            const totalSeconds = Math.floor((totalTime % (1000 * 60)) / 1000);
            const timeText = totalMinutes > 0 ? 
                `${totalMinutes}分${totalSeconds}秒` : 
                `${totalSeconds}秒`;
            
            loadingIndicator.innerHTML = `<p>生成完成！<br>总耗时：${timeText}</p>`;

            // 自动解析回复
            parseAIResponse();
            break; // 成功后跳出循环

        } catch (error) {
            retryCount++;
            
            if (error.name === 'AbortError') {
                loadingIndicator.innerHTML = `<p>请求超时，正在重试 (${retryCount}/${config.maxRetries})...<br>已用时：${Math.floor((Date.now() - startTime) / 1000)}秒</p>`;
            } else {
                loadingIndicator.innerHTML = `<p>请求失败，正在重试 (${retryCount}/${config.maxRetries}): ${error.message}<br>已用时：${Math.floor((Date.now() - startTime) / 1000)}秒</p>`;
            }

            if (retryCount > config.maxRetries) {
                const totalTime = Date.now() - startTime;
                const totalMinutes = Math.floor(totalTime / (1000 * 60));
                const totalSeconds = Math.floor((totalTime % (1000 * 60)) / 1000);
                const timeText = totalMinutes > 0 ? 
                    `${totalMinutes}分${totalSeconds}秒` : 
                    `${totalSeconds}秒`;
                
                loadingIndicator.innerHTML = `<p>请求失败！<br>总耗时：${timeText}</p>`;
                alert(`调用 API 失败: ${error.message}\n已重试 ${config.maxRetries} 次\n总耗时：${timeText}`);
                break;
            }

            // 等待一段时间后重试
            await new Promise(resolve => setTimeout(resolve, config.retryDelay));
        }
    }

    // 清除计时器
    clearInterval(timerInterval);
    
    // 3秒后隐藏加载指示器
    setTimeout(() => {
        loadingIndicator.style.display = 'none';
    }, 3000);
}

function getApiKey() {
    return API_KEYS.stepfun;
}

// 示例数据初始化
function initializeSampleData() {
    console.log('开始加载示例数据...');
    
    // 示例食材数据
    const sampleIngredients = [
        // 肉类
        {
            name: "猪里脊",
            category: "肉类",
            quantity: 500,
            unit: "克",
            purchaseDate: new Date(),
            expiryDate: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000) // 2天后过期
        },
        {
            name: "鸡胸肉",
            category: "肉类",
            quantity: 300,
            unit: "克",
            purchaseDate: new Date(),
            expiryDate: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000)
        },
        // 蔬菜
        {
            name: "胡萝卜",
            category: "蔬菜",
            quantity: 3,
            unit: "个",
            purchaseDate: new Date(),
            expiryDate: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000)
        },
        {
            name: "土豆",
            category: "蔬菜",
            quantity: 4,
            unit: "个",
            purchaseDate: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000),
            expiryDate: new Date(Date.now() + 8 * 24 * 60 * 60 * 1000)
        },
        {
            name: "西兰花",
            category: "蔬菜",
            quantity: 2,
            unit: "颗",
            purchaseDate: new Date(),
            expiryDate: new Date(Date.now() + 4 * 24 * 60 * 60 * 1000)
        },
        {
            name: "生菜",
            category: "蔬菜",
            quantity: 1,
            unit: "颗",
            purchaseDate: new Date(),
            expiryDate: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000)
        },
        // 调味料
        {
            name: "生抽",
            category: "调味料",
            quantity: 500,
            unit: "毫升",
            purchaseDate: new Date(),
            expiryDate: new Date(Date.now() + 180 * 24 * 60 * 60 * 1000)
        },
        {
            name: "蒜末",
            category: "调味料",
            quantity: 100,
            unit: "克",
            purchaseDate: new Date(),
            expiryDate: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000)
        },
        // 主食
        {
            name: "大米",
            category: "主食",
            quantity: 2,
            unit: "千克",
            purchaseDate: new Date(),
            expiryDate: new Date(Date.now() + 180 * 24 * 60 * 60 * 1000)
        },
        {
            name: "面条",
            category: "主食",
            quantity: 500,
            unit: "克",
            purchaseDate: new Date(),
            expiryDate: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000)
        },
        // 蛋类
        {
            name: "鸡蛋",
            category: "蛋类",
            quantity: 10,
            unit: "个",
            purchaseDate: new Date(),
            expiryDate: new Date(Date.now() + 15 * 24 * 60 * 60 * 1000)
        },
        // 豆制品
        {
            name: "豆腐",
            category: "豆制品",
            quantity: 400,
            unit: "克",
            purchaseDate: new Date(),
            expiryDate: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000)
        }
    ];

    // 清空现有数据
    window.ingredients.length = 0;
    window.meals.length = 0;

    // 添加示例食材
    sampleIngredients.forEach(item => {
        window.ingredients.push({
            id: Date.now() + Math.random(),
            ...item
        });
    });

    // 示例历史记录（过去6天的饮食记录）
    const sampleMeals = [
        "红烧排骨配米饭",
        "清炒小白菜",
        "番茄炒蛋",
        "麻婆豆腐",
        "蒜蓉西兰花",
        "可乐鸡翅"
    ];

    // 添加示例历史记录
    window.meals.push(...sampleMeals);

    console.log('示例数据加载完成:', { ingredients: window.ingredients, meals: window.meals });

    // 更新显示
    updateIngredientList();
    updateMealHistory();
}

// 页面加载时的初始化
document.addEventListener('DOMContentLoaded', function() {
    console.log('页面加载完成，开始初始化...');
    
    // 绑定示例数据加载按钮
    const loadSampleDataBtn = document.getElementById('loadSampleDataBtn');
    if (loadSampleDataBtn) {
        console.log('找到示例数据按钮，绑定点击事件');
        loadSampleDataBtn.addEventListener('click', initializeSampleData);
    } else {
        console.error('未找到示例数据按钮！');
    }
    
    // 更新数量输入框
    const unitSelect = document.getElementById('unit');
    unitSelect.addEventListener('change', updateQuantityInput);
    updateQuantityInput();
    
    // 绑定按钮事件
    document.getElementById('addIngredientBtn').addEventListener('click', addIngredient);
    document.getElementById('addMealBtn').addEventListener('click', addMeal);
    document.getElementById('generatePromptBtn').addEventListener('click', generatePrompt);
    document.getElementById('copyPromptBtn').addEventListener('click', copyPrompt);
    document.getElementById('callOpenAIBtn').addEventListener('click', callOpenAI);
    document.getElementById('parseResponseBtn').addEventListener('click', parseAIResponse);

    // 使用事件委托处理删除操作
    document.getElementById('ingredientList').addEventListener('click', function(e) {
        if (e.target.classList.contains('remove-btn')) {
            const item = e.target.closest('.ingredient-item');
            if (item) {
                const id = parseInt(item.dataset.id);
                removeIngredient(id);
            }
        }
    });

    document.getElementById('mealHistory').addEventListener('click', function(e) {
        if (e.target.classList.contains('remove-btn')) {
            const item = e.target.closest('.ingredient-item');
            if (item) {
                const index = parseInt(item.dataset.index);
                removeMeal(index);
            }
        }
    });
}); 