const bcrypt = require('bcryptjs');
const nodemailer = require('nodemailer');
const User = require('./User');

const resetCodes = {};

const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: 'disaisa01@gmail.com',
        pass: 'oyfjcgjtbkzifiyf' 
    }
});

// Құпия сөзді тексеру функциясы
const validatePassword = (password) => {
    // Минимум 8 таңба, 1 үлкен, 1 кіші, 1 сан, 1 арнайы символ
    const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*()_+={}\[\]|\\:;"'<,>.?/~`])[A-Za-z\d!@#$%^&*()_+={}\[\]|\\:;"'<,>.?/~`]{8,}$/;
    return passwordRegex.test(password);
};

async function sendResetCode(email) {
    if (!email) {
        return { status: 400, error: 'Email талап етіледі.' };
    }

    const user = await User.findOne({ email });

    if (!user) {
        return { status: 404, error: 'Бұл email тіркелмеген.' };
    }

    const resetCode = Math.floor(100000 + Math.random() * 900000).toString(); 
    const expirationTime = Date.now() + 3600000;

    resetCodes[email] = { code: resetCode, expires: expirationTime, userId: user.userId };
    
    try {
        await transporter.sendMail({
            from: 'disaisa01@gmail.com',
            to: email,
            subject: 'Құпия сөзді қалпына келтіру коды',
            text: `Сіздің құпия сөзді қалпына келтіру кодыңыз: ${resetCode}. Бұл код 1 сағат ішінде жарамды.`,
            html: `<p>Сіздің құпия сөзді қалпына келтіру <strong>кодыңыз: ${resetCode}</strong>. Бұл код 1 сағат ішінде жарамды.</p>`
        });
        return { status: 200, message: 'Қалпына келтіру коды email-ге жіберілді.' };
    } catch (e) {
        console.error('Nodemailer error:', e);
        return { status: 500, error: 'Кодты жіберу кезінде қате пайда болды. Сервер конфигурациясын тексеріңіз.' };
    }
}


function verifyResetCode(email, code) {
    if (!email || !code) {
        return { status: 400, error: 'Email және код талап етіледі.' };
    }

    const resetData = resetCodes[email];

    if (!resetData) {
        return { status: 400, error: 'Бірінші кодты сұраңыз.' };
    }

    if (resetData.expires < Date.now()) {
        delete resetCodes[email];
        return { status: 400, error: 'Кодтың мерзімі өтті. Қайта сұраңыз.' };
    }

    if (resetData.code !== code) {
        return { status: 400, error: 'Дұрыс емес код.' };
    }

    return { status: 200, message: 'Код сәтті расталды.', userId: resetData.userId };
}


async function resetPassword(email, newPassword) {
    if (!email || !newPassword) {
        return { status: 400, error: 'Email және жаңа құпия сөз талап етіледі.' };
    }

    if (!validatePassword(newPassword)) {
        return { 
            status: 400, 
            error: 'Құпия сөз кемінде 8 таңбадан тұруы керек және бір үлкен әріп, бір кіші әріп, бір сан және бір арнайы символ болуы керек.'
        };
    }
    
    const resetData = resetCodes[email];
    if (!resetData) {
        return { status: 400, error: 'Қалпына келтіру процесін қайта бастаңыз.' };
    }
    
    const hashedPassword = await bcrypt.hash(newPassword, 10);

    const result = await User.updateOne(
        { email: email },
        { $set: { password: hashedPassword } }
    );

    if (result.matchedCount === 0) {
        return { status: 404, error: 'Пайдаланушы табылмады.' };
    }

    delete resetCodes[email]; 

    return { status: 200, message: 'Құпия сөз сәтті жаңартылды.' };
}

module.exports = {
    sendResetCode,
    verifyResetCode,
    resetPassword,
    validatePassword // Тексеру функциясын экспорттау
};